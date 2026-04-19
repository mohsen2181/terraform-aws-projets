import boto3

waf = boto3.client('wafv2', region_name='us-east-1')

IP_SET_ID = "REPLACE"
IP_SET_NAME = "blocked-ips"

def lambda_handler(event, context):
    response = waf.get_ip_set(
        Name=IP_SET_NAME,
        Scope='CLOUDFRONT',
        Id=IP_SET_ID
    )

    addresses = response['IPSet']['Addresses']

    suspicious_ip = "176.147.243.147/32"  # replace with logic later

    if suspicious_ip not in addresses:
        addresses.append(suspicious_ip)

        waf.update_ip_set(
            Name=IP_SET_NAME,
            Scope='CLOUDFRONT',
            Id=IP_SET_ID,
            Addresses=addresses,
            LockToken=response['LockToken']
        )

    return "Updated"