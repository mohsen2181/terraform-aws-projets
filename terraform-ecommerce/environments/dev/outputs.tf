# Networking Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private App Subnet IDs"
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private DB Subnet IDs"
  value       = module.vpc.private_db_subnet_ids
}

output "alb_security_group_id" {
  description = "Internal ALB Security Group ID"
  value       = module.vpc.alb_security_group_id
}

output "ecs_tasks_security_group_id" {
  description = "ECS Tasks Security Group ID"
  value       = module.vpc.ecs_tasks_security_group_id
}

output "rds_security_group_id" {
  description = "RDS PostgreSQL Security Group ID"
  value       = module.vpc.rds_security_group_id
}

# Database Outputs
output "rds_endpoint" {
  description = "RDS connection endpoint"
  value       = module.database.rds_endpoint
}

output "rds_address" {
  description = "RDS hostname address"
  value       = module.database.rds_address
}

output "products_table_name" {
  description = "Products DynamoDB table name"
  value       = module.database.products_table_name
}

output "cart_table_name" {
  description = "Cart DynamoDB table name"
  value       = module.database.cart_table_name
}

# Auth Outputs
output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.auth.cognito_user_pool_id
}

output "cognito_client_id" {
  description = "Cognito App Client ID"
  value       = module.auth.cognito_client_id
}

# Notification Outputs
output "sns_topic_arn" {
  description = "Order events SNS Topic ARN"
  value       = module.notification.sns_topic_arn
}

output "sqs_queue_url" {
  description = "Order shipping SQS Queue URL"
  value       = module.notification.sqs_queue_url
}

# ALB Outputs
output "alb_dns_name" {
  description = "Internal ALB DNS Name"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "Internal ALB ARN"
  value       = module.alb.alb_arn
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "ECR Repository URLs"
  value       = module.ecr.repository_urls
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ECS Cluster ARN"
  value       = module.ecs.cluster_arn
}

output "ecs_service_names" {
  description = "Names of the deployed ECS services"
  value       = module.ecs.service_names
}

# API Gateway Outputs
output "api_gateway_url" {
  description = "HTTP API Gateway invoke URL"
  value       = module.apigateway.api_gateway_url
}

output "api_gateway_id" {
  description = "HTTP API Gateway ID"
  value       = module.apigateway.api_id
}

output "vpc_link_id" {
  description = "VPC Link ID"
  value       = module.apigateway.vpc_link_id
}

# Frontend Outputs
output "frontend_bucket_name" {
  description = "S3 Frontend Bucket Name"
  value       = module.frontend.frontend_bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = module.frontend.cloudfront_distribution_id
}

output "cloudfront_url" {
  description = "CloudFront Distribution URL"
  value       = module.frontend.cloudfront_url
}

output "certificate_arn" {
  description = "ACM Certificate ARN"
  value       = module.frontend.certificate_arn
}

output "custom_domain_url" {
  description = "Primary custom domain HTTPS URL"
  value       = module.frontend.custom_domain_url
}

output "subdomain_urls" {
  description = "Subdomain HTTPS URLs"
  value       = module.frontend.subdomain_urls
}

# Order Processor Lambda Outputs
output "order_processor_lambda_name" {
  description = "Order processor Lambda function name"
  value       = module.order_processor.lambda_function_name
}

output "order_processor_lambda_arn" {
  description = "Order processor Lambda function ARN"
  value       = module.order_processor.lambda_function_arn
}

# Monitoring & Dashboard Outputs
output "cloudwatch_dashboard_name" {
  description = "Operational CloudWatch Dashboard Name"
  value       = module.monitoring.dashboard_name
}

output "cloudwatch_dashboard_url" {
  description = "Direct AWS Console URL to access the operational CloudWatch dashboard"
  value       = module.monitoring.dashboard_url
}

output "alerts_sns_topic_arn" {
  description = "ARN of the SNS topic for critical CloudWatch alarms"
  value       = module.monitoring.alerts_sns_topic_arn
}
