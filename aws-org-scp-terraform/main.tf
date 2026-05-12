resource "aws_organizations_organization" "this" {
  feature_set = "ALL"

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]
}

locals {
  root_id = aws_organizations_organization.this.roots[0].id
}

module "security_ou" {
  source    = "./modules/organizational-unit"
  name      = var.organization_ous.security
  parent_id = local.root_id
}

module "infrastructure_ou" {
  source    = "./modules/organizational-unit"
  name      = var.organization_ous.infrastructure
  parent_id = local.root_id
}

module "sandbox_ou" {
  source    = "./modules/organizational-unit"
  name      = var.organization_ous.sandbox
  parent_id = local.root_id
}

module "workloads_ou" {
  source    = "./modules/organizational-unit"
  name      = var.organization_ous.workloads
  parent_id = local.root_id
}

module "dev_ou" {
  source    = "./modules/organizational-unit"
  name      = var.organization_ous.dev
  parent_id = module.workloads_ou.id
}

module "test_ou" {
  source    = "./modules/organizational-unit"
  name      = var.organization_ous.test
  parent_id = module.workloads_ou.id
}

module "prod_ou" {
  source    = "./modules/organizational-unit"
  name      = var.organization_ous.prod
  parent_id = module.workloads_ou.id
}

module "baseline_security_scp" {
  source = "./modules/scp"

  name        = "BaselineSecurityControls"
  description = "Baseline security guardrails for member accounts"
  policy_file = "${path.module}/policies/baseline-security-controls.json"
}

module "restrict_regions_scp" {
  source = "./modules/scp"

  name        = "RestrictRegions"
  description = "Allow operations only in approved AWS regions"
  policy_file = "${path.module}/policies/restrict-regions.json"
}

module "baseline_security_attachment_sandbox" {
  source = "./modules/scp-attachment"

  policy_id = module.baseline_security_scp.id
  target_id = module.sandbox_ou.id
}

module "restrict_regions_attachment_sandbox" {
  source = "./modules/scp-attachment"

  policy_id = module.restrict_regions_scp.id
  target_id = module.sandbox_ou.id
}

module "sandbox_test_account" {
  source    = "./modules/account"
  name      = var.sandbox_account.name
  email     = var.sandbox_account.email
  parent_id = module.sandbox_ou.id
}

