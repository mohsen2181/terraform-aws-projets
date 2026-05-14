variable "table_name" {
  description = "Name of the DynamoDB global table."
  type        = string
}

variable "secondary_region" {
  description = "Secondary AWS region for DynamoDB replica."
  type        = string
}
