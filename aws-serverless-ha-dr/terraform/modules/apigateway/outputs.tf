output "rest_api_id" {
  value = aws_api_gateway_rest_api.this.id
}

output "execution_arn" {
  value = aws_api_gateway_rest_api.this.execution_arn
}

output "invoke_url" {
  value = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.stage_name}"
}

output "regional_domain_name" {
  value = aws_api_gateway_domain_name.this.regional_domain_name
}

output "regional_zone_id" {
  value = aws_api_gateway_domain_name.this.regional_zone_id
}
