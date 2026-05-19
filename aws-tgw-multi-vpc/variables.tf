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
