variable "region" {
  default = "us-east-1"
}

variable "bucket_name" {
  default = "tf-oac-demo-bucket-12345"
}

variable "alert_email" {
  description = "Email address for SNS alerts"
  type        = string
}