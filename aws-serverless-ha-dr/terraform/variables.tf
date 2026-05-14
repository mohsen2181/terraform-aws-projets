variable "project_name" {
  description = "Project name used for naming AWS resources."
  type        = string
  default     = "serverless-ha-dr"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "primary_region" {
  description = "Primary AWS region."
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region."
  type        = string
  default     = "us-west-2"
}

variable "table_name" {
  description = "DynamoDB global table name."
  type        = string
  default     = "HighAvailabilityTable"
}

variable "common_tags" {
  description = "Common tags applied to all supported AWS resources."
  type        = map(string)

  default = {
    Project     = "serverless-ha-dr"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

variable "domain_name" {
  description = "Root domain name managed in Route 53."
  type        = string
}

variable "api_subdomain" {
  description = "API subdomain."
  type        = string
  default     = "api"
}

variable "frontend_bucket_name" {
  description = "S3 bucket name for the frontend website."
  type        = string
}
