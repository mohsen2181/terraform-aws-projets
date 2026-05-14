output "table_name" {
  description = "DynamoDB table name."
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "DynamoDB table ARN in primary region."
  value       = aws_dynamodb_table.this.arn
}

output "stream_arn" {
  description = "DynamoDB stream ARN."
  value       = aws_dynamodb_table.this.stream_arn
}
