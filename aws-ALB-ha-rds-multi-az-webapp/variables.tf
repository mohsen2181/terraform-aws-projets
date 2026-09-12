variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name tag"
  type        = string
  default     = "production"
}

variable "domain_name" {
  description = "Domain name for Route 53 and ACM Certificate (e.g., yourdomain.com)"
  type        = string
}

variable "enable_route53" {
  description = "Flag to enable/disable Route 53 and ACM"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for Public Subnet in AZ 1"
  type        = string
  default     = "10.10.0.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for Public Subnet in AZ 2"
  type        = string
  default     = "10.10.1.0/24"
}

variable "web_subnet_1_cidr" {
  description = "CIDR block for Private Web Subnet in AZ 1"
  type        = string
  default     = "10.10.13.0/24"
}

variable "web_subnet_2_cidr" {
  description = "CIDR block for Private Web Subnet in AZ 2"
  type        = string
  default     = "10.10.14.0/24"
}

variable "db_subnet_1_cidr" {
  description = "CIDR block for Private DB Subnet in AZ 1"
  type        = string
  default     = "10.10.11.0/24"
}

variable "db_subnet_2_cidr" {
  description = "CIDR block for Private DB Subnet in AZ 2"
  type        = string
  default     = "10.10.12.0/24"
}

variable "instance_type" {
  description = "EC2 Instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Optional SSH key name for EC2 instances"
  type        = string
  default     = null
}

variable "db_name" {
  description = "MySQL database name"
  type        = string
  default     = "sampledb"
}

variable "db_username" {
  description = "MySQL database master username"
  type        = string
  default     = "dbadmin"
}

# Sensitive variable: NO default value to prevent committing passwords to Git
variable "db_password" {
  description = "MySQL database master password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS DB instance class"
  type        = string
  default     = "db.t3.micro"
}
