variable "aws_region" {
  description = "AWS region for the lab"
  type        = string
}

variable "my_ip" {
  description = "Public IP address allowed for temporary DataSync agent HTTP activation"
  type        = string
}
