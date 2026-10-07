variable "project_name" {
  description = "Name prefix for resources"
  type        = string
  default     = "ecommerce"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to deploy subnets into"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (NAT Gateway / Ingress)"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private app subnets (ECS tasks & Internal ALB)"
  type        = list(string)
  default     = ["10.10.11.0/24", "10.10.12.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets (RDS PostgreSQL)"
  type        = list(string)
  default     = ["10.10.21.0/24", "10.10.22.0/24"]
}

variable "aws_region" {
  description = "AWS deployment region for VPC endpoints"
  type        = string
  default     = "us-east-1"
}
