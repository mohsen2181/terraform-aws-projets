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

variable "services" {
  description = "List of microservices names for ECR repositories"
  type        = list(string)
  default     = ["product-service", "cart-service", "user-service", "order-service"]
}
