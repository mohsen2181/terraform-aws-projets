############################################
# DynamoDB table for blocked IPs
############################################
resource "aws_dynamodb_table" "blocked_ips" {
  name         = "blocked-ips-table"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "ip"

  attribute {
    name = "ip"
    type = "S"
  }
}