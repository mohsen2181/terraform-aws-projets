output "api_url" {
  value = aws_apigatewayv2_api.api.api_endpoint
}
output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}
