output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "website_url" {
  value = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}
