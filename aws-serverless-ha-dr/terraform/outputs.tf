output "primary_api_url" {
  description = "Primary API Gateway invoke URL."
  value       = module.api_gateway_primary.invoke_url
}

output "secondary_api_url" {
  description = "Secondary API Gateway invoke URL."
  value       = module.api_gateway_secondary.invoke_url
}

output "primary_read_endpoint" {
  value = "${module.api_gateway_primary.invoke_url}/read"
}

output "primary_write_endpoint" {
  value = "${module.api_gateway_primary.invoke_url}/write"
}

output "secondary_read_endpoint" {
  value = "${module.api_gateway_secondary.invoke_url}/read"
}

output "secondary_write_endpoint" {
  value = "${module.api_gateway_secondary.invoke_url}/write"
}

output "failover_api_url" {
  value = "https://${module.route53_failover.fqdn}"
}

output "frontend_url" {
  value = module.s3_frontend.website_url
}

output "cognito_user_pool_id" {
  value = module.cognito_primary.user_pool_id
}

output "cognito_user_pool_client_id" {
  value = module.cognito_primary.user_pool_client_id
}

output "aws_region" {
  value = var.primary_region
}