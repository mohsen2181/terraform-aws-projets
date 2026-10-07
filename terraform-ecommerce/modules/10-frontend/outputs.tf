output "frontend_bucket_name" {
  description = "Frontend S3 bucket name"
  value       = aws_s3_bucket.frontend.bucket
}

output "frontend_bucket_arn" {
  description = "Frontend S3 bucket ARN"
  value       = aws_s3_bucket.frontend.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.cdn.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_url" {
  description = "CloudFront distribution HTTPS URL"
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "certificate_arn" {
  description = "ACM Certificate ARN"
  value       = aws_acm_certificate_validation.cert_validation.certificate_arn
}

output "custom_domain_url" {
  description = "Primary custom domain HTTPS URL"
  value       = "https://${var.domain_name}"
}

output "subdomain_urls" {
  description = "Subdomain HTTPS URLs"
  value       = [for sub in var.subdomains : "https://${sub}"]
}
