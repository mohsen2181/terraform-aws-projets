import json
import boto3
import psycopg2
import os

secrets_client = boto3.client("secretsmanager")


def get_db_credentials():
    secret = secrets_client.get_secret_value(
        SecretId=os.environ["SECRET_NAME"]
    )
    return json.loads(secret["SecretString"])


def get_connection():
    creds = get_db_credentials()
    return psycopg2.connect(
        host=creds["host"],
        user=creds["username"],
        password=creds["password"],
        dbname=creds["dbname"],
        port=creds["port"]
    )


def lambda_handler(event, context):
    try:
        http_method = (
            event.get("requestContext", {}).get("http", {}).get("method")
            or event.get("httpMethod")
        )

        if http_method == "POST":
            body = json.loads(event.get("body", "{}"))

            name = body.get("name")
            message = body.get("message")

            if not name or not message:
                return {
                    "statusCode": 400,
                    "body": json.dumps({"error": "Missing fields"})
                }

            conn = get_connection()
            cur = conn.cursor()

            cur.execute(
                "INSERT INTO messages (name, message) VALUES (%s, %s)",
                (name, message)
            )

            conn.commit()
            cur.close()
            conn.close()

            return {
                "statusCode": 200,
                "body": json.dumps({"status": "stored"})
            }

        elif http_method == "GET":
            conn = get_connection()
            cur = conn.cursor()

            cur.execute("""
                SELECT id, name, message, created_at
                FROM messages
                ORDER BY id DESC
                LIMIT 50
            """)

            rows = cur.fetchall()

            messages = [
                {
                    "id": row[0],
                    "name": row[1],
                    "message": row[2],
                    "created_at": str(row[3]) if row[3] else None
                }
                for row in rows
            ]

            cur.close()
            conn.close()

            return {
                "statusCode": 200,
                "body": json.dumps(messages)
            }

        return {
            "statusCode": 405,
            "body": json.dumps({
                "error": "Method not allowed",
                "detected_method": http_method
            })
        }

    except Exception as e:
        print(f"ERROR: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }