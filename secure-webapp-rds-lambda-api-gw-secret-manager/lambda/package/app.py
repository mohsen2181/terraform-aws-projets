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


def lambda_handler(event, context):
    body = json.loads(event.get("body", "{}"))

    name = body.get("name")
    message = body.get("message")

    if not name or not message:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Missing fields"})
        }

    creds = get_db_credentials()

    conn = psycopg2.connect(
        host=creds["host"],
        user=creds["username"],
        password=creds["password"],
        dbname=creds["dbname"],
        port=creds["port"]
    )

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