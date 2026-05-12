variable "name" {
  description = "Organizational Unit name"
  type        = string
}

variable "parent_id" {
  description = "Parent ID, either root ID or parent OU ID"
  type        = string
}
