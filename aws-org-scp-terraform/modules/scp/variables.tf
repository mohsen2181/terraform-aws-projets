variable "name" {
  description = "SCP name"
  type        = string
}

variable "description" {
  description = "SCP description"
  type        = string
}

variable "policy_file" {
  description = "Path to SCP JSON policy file"
  type        = string
}
