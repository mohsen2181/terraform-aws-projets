variable "function_name" {
  type = string
}

variable "handler" {
  type = string
}

variable "runtime" {
  type    = string
  default = "python3.12"
}

variable "source_dir" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "table_name" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 7
}