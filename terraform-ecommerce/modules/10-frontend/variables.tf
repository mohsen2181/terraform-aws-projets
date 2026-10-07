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

variable "domain_name" {
  description = "Primary root custom domain name (Route 53 hosted zone)"
  type        = string
}

variable "subdomains" {
  description = "List of subdomains to alias to CloudFront distribution"
  type        = list(string)
  default     = []
}
