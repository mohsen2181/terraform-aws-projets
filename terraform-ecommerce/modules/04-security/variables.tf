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

variable "db_host" {
  description = "RDS PostgreSQL endpoint hostname"
  type        = string
}

variable "db_password" {
  description = "RDS PostgreSQL master password"
  type        = string
  sensitive   = true
}

variable "sns_topic_arn" {
  description = "ARN of the order events SNS topic"
  type        = string
}
