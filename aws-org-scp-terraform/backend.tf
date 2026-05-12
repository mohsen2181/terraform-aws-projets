terraform {
  backend "s3" {
    bucket       = "aws-org-scp-terraform-terraform-state"
    key          = "aws-organizations/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}
