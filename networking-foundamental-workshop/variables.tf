variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "vpc_name" {
  description = "VPC Name"
  type        = string
  default     = "VPC-A"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_az1_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "private_subnet_az1_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "public_subnet_az2_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "private_subnet_az3_cidr" {
  type    = string
  default = "10.0.3.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "public_instance_private_ip" {
  description = "Static private IP for public EC2"
  type        = string
  default     = "10.0.2.100"
}

variable "private_instance_private_ip" {
  description = "Static private IP for private EC2"
  type        = string
  default     = "10.0.1.100"
}
