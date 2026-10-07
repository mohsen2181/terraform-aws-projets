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

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue for order shipping"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Lambda will be deployed"
  type        = string
}

variable "private_app_subnet_ids" {
  description = "Private application subnet IDs for Lambda VPC connectivity"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Security group ID for RDS PostgreSQL"
  type        = string
}

variable "db_host" {
  description = "RDS PostgreSQL host endpoint"
  type        = string
}

variable "db_password" {
  description = "Master password for PostgreSQL database"
  type        = string
  sensitive   = true
}
