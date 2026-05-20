variable "name" {
  description = "VPC name."
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block."
  type        = string
}

variable "azs" {
  description = "Availability zones."
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDRs."
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDRs."
  type        = list(string)
}

variable "tgw_subnets" {
  description = "Dedicated TGW attachment subnet CIDRs."
  type        = list(string)
}

variable "allowed_internal_cidrs" {
  description = "CIDR blocks allowed in the private security group."
  type        = list(string)
}
