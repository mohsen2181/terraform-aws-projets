output "certificate_arn" {
  value = aws_acm_certificate_validation.api.certificate_arn
}

output "api_domain_name" {
  value = local.api_domain_name
}
