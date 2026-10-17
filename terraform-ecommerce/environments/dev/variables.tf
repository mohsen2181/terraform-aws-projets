variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "ecommerce"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "db_password" {
  description = "Master password for PostgreSQL database"
  type        = string
  sensitive   = true
  default     = "EcomSecurePass123!"
}

variable "domain_name" {
  description = "Primary root custom domain name"
  type        = string
  default     = "mycloudhomelab.click"
}

variable "subdomains" {
  description = "List of subdomains for the frontend"
  type        = list(string)
  default     = ["www.mycloudhomelab.click", "ecommerce.mycloudhomelab.click"]
}
