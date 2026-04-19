output "cloudfront_url" {
  description = "Access your website via CloudFront"
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (useful for invalidations and debugging)"
  value       = aws_cloudfront_distribution.cdn.id
}

output "s3_bucket_name" {
  description = "Primary S3 bucket hosting the website content"
  value       = aws_s3_bucket.site.bucket
}

output "log_bucket" {
  description = "S3 bucket storing CloudFront access logs"
  value       = aws_s3_bucket.logs.bucket
}

output "log_location" {
  description = "Path inside the log bucket where CloudFront logs are stored"
  value       = "${aws_s3_bucket.logs.bucket}/cloudfront-logs/"
}
