# AWS Serverless HA/DR Lab — Testing Notes

## Architecture Overview

This project demonstrates a highly available and disaster recovery (HA/DR) serverless architecture on AWS using:

- DynamoDB Global Tables
- AWS Lambda
- API Gateway
- Route 53 Failover Routing
- Cognito Authentication
- S3 Static Website Hosting

Regions:

- Primary Region: `eu-west-3`
- Secondary Region: `eu-west-2`

---

# Terraform Outputs

```bash
cognito_user_pool_client_id = "1b45ptfo9ufj0gsmiu1e951od3"
cognito_user_pool_id = "eu-west-3_zTJZCd6YI"

failover_api_url = "https://api.aws-labs.click"
frontend_url = "http://aws-labs-click-serverless-ha-frontend.s3-website.eu-west-3.amazonaws.com"

primary_api_url = "https://ceva2tsmk8.execute-api.eu-west-3.amazonaws.com/prod"
primary_read_endpoint = "https://ceva2tsmk8.execute-api.eu-west-3.amazonaws.com/prod/read"
primary_write_endpoint = "https://ceva2tsmk8.execute-api.eu-west-3.amazonaws.com/prod/write"

secondary_api_url = "https://ed2dqxtu19.execute-api.eu-west-2.amazonaws.com/prod"
secondary_read_endpoint = "https://ed2dqxtu19.execute-api.eu-west-2.amazonaws.com/prod/read"
secondary_write_endpoint = "https://ed2dqxtu19.execute-api.eu-west-2.amazonaws.com/prod/write"
```

---

# 1. Basic DynamoDB Global Table Replication Test

## Write Through Primary Region

```bash
curl -X POST "$(terraform output -raw primary_write_endpoint)" \
  -H "Content-Type: application/json" \
  -d '{"ItemId":"item-001","Data":"Hello from eu-west-3 primary"}'
```

## Read From Primary Region

```bash
curl "$(terraform output -raw primary_read_endpoint)"
```

Expected:

```json
[{"ItemId": "item-001", "Data": "Hello from eu-west-3 primary"}]
```

## Read From Secondary Region

```bash
curl "$(terraform output -raw secondary_read_endpoint)"
```

Expected:

```json
[{"ItemId": "item-001", "Data": "Hello from eu-west-3 primary"}]
```

This validates DynamoDB Global Table replication.

---

# 2. Route 53 Failover DNS Validation

## Write Through Failover DNS

```bash
curl -X POST "https://api.aws-labs.click/write" \
  -H "Content-Type: application/json" \
  -d '{"ItemId":"item-002","Data":"Hello through Route53"}'
```

## Read Through Failover DNS

```bash
curl "https://api.aws-labs.click/read"
```

---

# 3. API Security Validation

## Root Path Test

```bash
curl https://api.aws-labs.click
```

Expected:

```json
{"message":"Missing Authentication Token"}
```

## Unauthorized Access Test

```bash
curl https://api.aws-labs.click/read
```

Expected:

```json
{"message":"Unauthorized"}
```

---

# 4. Cognito Authentication Setup

## Export Variables

```bash
export USER_POOL_ID="eu-west-3_zTJZCd6YI"
export CLIENT_ID="1b45ptfo9ufj0gsmiu1e951od3"
export AWS_REGION="eu-west-3"
```

---

# 5. Create Cognito Test User

```bash
aws cognito-idp sign-up \
  --client-id $CLIENT_ID \
  --username admin@aws-labs.click \
  --password 'Admin2016123!' \
  --user-attributes Name=email,Value=admin@aws-labs.click \
  --region $AWS_REGION
```

---

# 6. Confirm Cognito User

```bash
aws cognito-idp admin-confirm-sign-up \
  --user-pool-id $USER_POOL_ID \
  --username admin@aws-labs.click \
  --region $AWS_REGION
```

---

# 7. Authenticate and Retrieve JWT Tokens

```bash
aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id $CLIENT_ID \
  --auth-parameters USERNAME=admin@aws-labs.click,PASSWORD='Admin2016123!' \
  --region $AWS_REGION
```

Copy the returned `IdToken`.

## Export Token

```bash
export TOKEN="<IdToken>"
```

---

# 8. Authenticated API Requests

## Authenticated Write Request

```bash
curl -X POST https://api.aws-labs.click/write \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ItemId":"secure-item","Data":"Authenticated request"}'
```

## Authenticated Read Request

```bash
curl https://api.aws-labs.click/read \
  -H "Authorization: Bearer $TOKEN"
```

---

# 9. Frontend Validation

Open the frontend:

```text
http://aws-labs-click-serverless-ha-frontend.s3-website.eu-west-3.amazonaws.com
```

Login with:

```text
Email: admin@aws-labs.click
Password: Admin2016123!
```

Validate:

- Login works
- Read requests succeed
- Write requests succeed
- Browser sends Authorization Bearer token

---

# 10. Disaster Recovery (DR) Testing

## DR Concept

Normally:

```text
Route53 -> Primary API Gateway (eu-west-3)
```

If the primary API becomes unhealthy:

```text
Route53 -> Secondary API Gateway (eu-west-2)
```

The frontend continues using:

```text
https://api.aws-labs.click
```

without any modification.

---

# 11. Safe DR Test

Do NOT delete the API Gateway.

Instead, temporarily break the primary Lambda integration.

## Disable Primary Lambda Permission

```bash
aws lambda remove-permission \
  --function-name serverless-ha-dr-dev-read-primary \
  --statement-id AllowExecutionFromAPIGatewayRead \
  --region eu-west-3
```

---

# 12. Validate Failover

```bash
curl -i https://api.aws-labs.click/read \
  -H "Authorization: Bearer $TOKEN"
```

After Route53 health checks fail, traffic should automatically switch to:

```text
eu-west-2
```

Expected failover timing:

```text
~90 seconds + DNS cache time
```

Because:

```text
request_interval = 30
failure_threshold = 3
```

---

# 13. DR Write Validation

While failover is active, write new data:

```bash
curl -X POST https://api.aws-labs.click/write \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ItemId":"dr-test-001","Data":"Written during DR failover"}'
```

This write is handled entirely by:

```text
Secondary Region -> eu-west-2
```

---

# 14. Recovery Validation

Restore infrastructure:

```bash
terraform apply
```

Then validate replication back to the primary region.

## Read Directly From Primary Region

```bash
curl "$(terraform output -raw primary_read_endpoint)" \
  -H "Authorization: Bearer $TOKEN"
```

Expected:

```json
{
  "ItemId": "dr-test-001",
  "Data": "Written during DR failover"
}
```

This proves:

- Secondary region remained operational
- Writes continued during DR
- DynamoDB Global Tables replicated data back to primary region
- Recovery completed successfully

---

# Final Result

The project successfully demonstrates:

- High Availability (HA)
- Disaster Recovery (DR)
- Multi-region serverless architecture
- Secure API access with Cognito JWT authentication
- DynamoDB Global Table replication
- Route53 automatic failover
- S3-hosted frontend
- Least privilege IAM implementation
