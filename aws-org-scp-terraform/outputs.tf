output "organization_id" {
  value = aws_organizations_organization.this.id
}

output "root_id" {
  value = local.root_id
}

output "ou_ids" {
  value = {
    security       = module.security_ou.id
    infrastructure = module.infrastructure_ou.id
    sandbox        = module.sandbox_ou.id
    workloads      = module.workloads_ou.id
    dev            = module.dev_ou.id
    test           = module.test_ou.id
    prod           = module.prod_ou.id
  }
}
