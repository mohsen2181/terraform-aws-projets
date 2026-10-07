output "rds_endpoint" {
  description = "RDS connection endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "RDS connection hostname"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.postgres.port
}

output "products_table_name" {
  description = "Name of the products DynamoDB table"
  value       = aws_dynamodb_table.products.name
}

output "products_table_arn" {
  description = "ARN of the products DynamoDB table"
  value       = aws_dynamodb_table.products.arn
}

output "cart_table_name" {
  description = "Name of the cart DynamoDB table"
  value       = aws_dynamodb_table.cart.name
}

output "cart_table_arn" {
  description = "ARN of the cart DynamoDB table"
  value       = aws_dynamodb_table.cart.arn
}
