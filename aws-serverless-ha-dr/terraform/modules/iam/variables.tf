variable "project_name" {
  description = "Project name."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "table_arn" {
  description = "DynamoDB table ARN."
  type        = string
}


variable "table_name" {
  type = string
}

variable "primary_region" {
  type = string
}

variable "secondary_region" {
  type = string
}