import boto3
import os
import gzip
import io
from collections import defaultdict
from datetime import datetime

s3 = boto3.client("s3")
waf = boto3.client("wafv2", region_name=os.environ["REGION"])
sns = boto3.client("sns")
ddb = boto3.resource("dynamodb")

TABLE = ddb.Table(os.environ["DDB_TABLE"])

THRESHOLD = 100


def lambda_handler(event, context):

    bucket = event["Records"][0]["s3"]["bucket"]["name"]
    key = event["Records"][0]["s3"]["object"]["key"]

    # -------------------------------
    # Fetch S3 object
    # -------------------------------
    obj = s3.get_object(Bucket=bucket, Key=key)
    body = obj["Body"].read()

    # -------------------------------
    # Handle gzip or plain text
    # -------------------------------
    if body[:2] == b'\x1f\x8b':
        content = gzip.GzipFile(fileobj=io.BytesIO(body)).read().decode("utf-8")
    else:
        content = body.decode("utf-8")

    ip_count = defaultdict(int)

    # -------------------------------
    # Parse CloudFront logs
    # -------------------------------
    for line in content.splitlines():

        if not line or line.startswith("#"):
            continue

        fields = line.split()

        # CloudFront format safety check
        if len(fields) <= 4:
            continue

        ip = fields[4]  # c-ip
        ip_count[ip] += 1

    # -------------------------------
    # Detect suspicious IPs
    # -------------------------------
    suspicious_ips = [
        ip for ip, count in ip_count.items()
        if count > THRESHOLD
    ]

    if not suspicious_ips:
        return {"status": "no suspicious activity"}

    # -------------------------------
    # Get WAF IP Set
    # -------------------------------
    response = waf.get_ip_set(
        Name=os.environ["IP_SET_NAME"],
        Scope="CLOUDFRONT",
        Id=os.environ["IP_SET_ID"]
    )

    addresses = response["IPSet"]["Addresses"]
    lock_token = response["LockToken"]

    blocked_ips = []

    # -------------------------------
    # Add new IPs
    # -------------------------------
    for ip in suspicious_ips:
        ip_cidr = f"{ip}/32"

        if ip_cidr not in addresses:
            addresses.append(ip_cidr)
            blocked_ips.append(ip)

            # Store in DynamoDB
            TABLE.put_item(
                Item={
                    "ip": ip,
                    "timestamp": datetime.utcnow().isoformat(),
                    "requests": ip_count[ip],
                    "status": "blocked"
                }
            )

    # -------------------------------
    # Update WAF IP Set
    # -------------------------------
    if blocked_ips:
        waf.update_ip_set(
            Name=os.environ["IP_SET_NAME"],
            Scope="CLOUDFRONT",
            Id=os.environ["IP_SET_ID"],
            Addresses=addresses,
            LockToken=lock_token
        )

        # -------------------------------
        # Send SNS alert
        # -------------------------------
        sns.publish(
            TopicArn=os.environ["SNS_TOPIC_ARN"],
            Subject="🚨 WAF Alert - IPs Blocked",
            Message=(
                f"Blocked IPs: {blocked_ips}\n"
                f"Time: {datetime.utcnow().isoformat()}"
            )
        )

    return {
        "status": "processed",
        "blocked_ips": blocked_ips
    }