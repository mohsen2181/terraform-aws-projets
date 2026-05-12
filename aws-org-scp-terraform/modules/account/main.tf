resource "aws_organizations_account" "this" {
  name      = var.name
  email     = var.email
  parent_id = var.parent_id
}
