output "api_id" {
  description = "HTTP API Gateway ID"
  value       = aws_apigatewayv2_api.api.id
}

output "api_endpoint" {
  description = "HTTP API Gateway Endpoint"
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "api_gateway_url" {
  description = "API Gateway invocation URL"
  value       = "https://${aws_apigatewayv2_api.api.id}.execute-api.${var.aws_region}.amazonaws.com"
}

output "vpc_link_id" {
  description = "VPC Link ID"
  value       = aws_apigatewayv2_vpc_link.link.id
}
