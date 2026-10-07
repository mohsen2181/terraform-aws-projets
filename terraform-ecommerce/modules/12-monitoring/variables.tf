variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "ecommerce"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "api_gateway_id" {
  description = "HTTP API Gateway ID"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the internal ALB for CloudWatch metrics"
  type        = string
}

variable "rds_instance_identifier" {
  description = "Identifier of the RDS PostgreSQL instance"
  type        = string
  default     = "ecommercedb-instance"
}

variable "sqs_queue_name" {
  description = "Name of the order shipping SQS queue"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the order processor Lambda function"
  type        = string
}

variable "alert_email" {
  description = "Optional email address to receive critical CloudWatch alarm notifications"
  type        = string
  default     = ""
}
