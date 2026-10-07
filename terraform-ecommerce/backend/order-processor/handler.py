import json
import os
import uuid
import logging
import datetime
import urllib.request
import pg8000.native

# Configure structured logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

DB_HOST = os.environ.get("DB_HOST")
DB_NAME = os.environ.get("DB_NAME", "ecommercedb")
DB_USER = os.environ.get("DB_USER", "postgres")
DB_PASSWORD = os.environ.get("DB_PASSWORD")
DB_PORT = int(os.environ.get("DB_PORT", "5432"))

def get_db_connection():
    """Establish connection to PostgreSQL using pure-Python pg8000 driver."""
    return pg8000.native.Connection(
        user=DB_USER,
        host=DB_HOST,
        database=DB_NAME,
        port=DB_PORT,
        password=DB_PASSWORD,
        timeout=10
    )

def process_order_event(event_data):
    """
    Simulates warehouse shipping fulfillment:
    1. Generates carrier tracking number
    2. Updates order status in RDS from 'Order Placed' to 'Shipped'
    """
    order_id = event_data.get("order_id")
    user_email = event_data.get("user_email")
    total_amount = event_data.get("total_amount")
    items = event_data.get("items", [])

    tracking_number = f"TRK-US-{uuid.uuid4().hex[:10].upper()}"
    shipped_at = datetime.datetime.utcnow().isoformat()

    logger.info(f"Processing Order #{order_id} for {user_email} | Total: ${total_amount} | Items: {len(items)}")

    if not DB_HOST or not DB_PASSWORD:
        logger.warning("DB_HOST or DB_PASSWORD not configured. Skipping RDS update (dry-run mode).")
        return {
            "order_id": order_id,
            "status": "Shipped",
            "tracking_number": tracking_number,
            "dry_run": True
        }

    try:
        conn = get_db_connection()
        # Update order status in PostgreSQL
        conn.run(
            "UPDATE orders SET status = :status WHERE id = :order_id",
            status="Shipped",
            order_id=order_id
        )
        conn.close()
        logger.info(f"Successfully updated Order #{order_id} status to 'Shipped' in RDS.")
    except Exception as e:
        logger.error(f"Failed to update RDS database for Order #{order_id}: {str(e)}")
        raise e

    return {
        "order_id": order_id,
        "user_email": user_email,
        "status": "Shipped",
        "tracking_number": tracking_number,
        "shipped_at": shipped_at,
        "item_count": len(items)
    }

def lambda_handler(event, context):
    """
    Main SQS Event Trigger Entrypoint
    """
    records = event.get("Records", [])
    logger.info(f"Received {len(records)} SQS message(s) for processing.")

    results = []
    for record in records:
        message_id = record.get("messageId")
        body_raw = record.get("body", "{}")

        try:
            body_json = json.loads(body_raw)

            # SQS subscribed to SNS wraps message in "Message" key
            if "Message" in body_json and isinstance(body_json["Message"], str):
                order_payload = json.loads(body_json["Message"])
            elif "Message" in body_json and isinstance(body_json["Message"], dict):
                order_payload = body_json["Message"]
            else:
                order_payload = body_json

            result = process_order_event(order_payload)
            results.append(result)
            logger.info(f"Message {message_id} processed successfully: {result}")

        except Exception as err:
            logger.error(f"Error processing SQS record {message_id}: {str(err)}", exc_info=True)
            # Re-raise so SQS can retry or route to DLQ
            raise err

    return {
        "statusCode": 200,
        "processed_count": len(results),
        "results": results
    }
