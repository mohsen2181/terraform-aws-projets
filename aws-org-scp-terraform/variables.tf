variable "aws_region" {
  description = "Terraform AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "organization_ous" {
  description = "Organization OU names"
  type = object({
    security       = string
    infrastructure = string
    sandbox        = string
    workloads      = string
    dev            = string
    test           = string
    prod           = string
  })
}

variable "sandbox_account" {
  description = "Sandbox account configuration"

  type = object({
    name  = string
    email = string
  })
}
