variable "budget_name" {
  description = "Name for the AWS Cost Budget"
  type        = string
  default     = "ecommerce-monthly-budget"
}

variable "budget_amount" {
  description = "Monthly budget limit in USD"
  type        = string
  default     = "25.0"
}

variable "notification_emails" {
  description = "List of email addresses for budget alerts"
  type        = list(string)
  default     = ["admin@mycloudhomelab.click"]
}

variable "alarm_threshold" {
  description = "CloudWatch billing alarm threshold in USD"
  type        = number
  default     = 20
}
