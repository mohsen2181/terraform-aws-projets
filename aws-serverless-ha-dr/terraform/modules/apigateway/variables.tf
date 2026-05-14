variable "api_name" {
  type = string
}

variable "stage_name" {
  type    = string
  default = "prod"
}

variable "read_lambda_name" {
  type = string
}

variable "read_lambda_invoke_arn" {
  type = string
}

variable "write_lambda_name" {
  type = string
}

variable "write_lambda_invoke_arn" {
  type = string
}


variable "custom_domain_name" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "throttling_rate_limit" {
  type    = number
  default = 10
}

variable "throttling_burst_limit" {
  type    = number
  default = 20
}

variable "cognito_user_pool_arn" {
  type    = string
  default = null
}

variable "enable_cognito_auth" {
  type    = bool
  default = false
}