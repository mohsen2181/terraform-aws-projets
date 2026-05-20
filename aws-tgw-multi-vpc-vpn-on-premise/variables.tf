variable "aws_region" {
  description = "AWS region where the architecture will be deployed."
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Prefix used for resource names."
  type        = string
  default     = "tgw-lab"
}

variable "enable_test_instances" {
  description = "Create one EC2 test instance in each VPC private subnet."
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "EC2 instance type used for connectivity tests."
  type        = string
  default     = "t3.micro"
}


variable "onprem_vpc_cidr" {
  description = "CIDR block for the simulated on-premises VPC."
  type        = string
  default     = "172.16.0.0/16"
}

variable "onprem_public_subnet_cidr" {
  description = "CIDR block for the simulated on-premises public subnet."
  type        = string
  default     = "172.16.0.0/24"
}

variable "onprem_private_subnet_cidr" {
  description = "CIDR block for the simulated on-premises private subnet."
  type        = string
  default     = "172.16.1.0/24"
}

variable "participant_ip_address" {
  description = "Your public IP in x.x.x.x/32 format for temporary testing access."
  type        = string
}