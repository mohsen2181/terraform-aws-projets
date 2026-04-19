############################################
# Origin Access Control (OAC)
############################################
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-oac-demo"
  description                       = "OAC for S3 private access"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

############################################
# CloudFront Distribution
############################################
resource "aws_cloudfront_distribution" "cdn" {

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ############################################
  # Attach WAF (from waf.tf)
  ############################################
  web_acl_id = aws_wafv2_web_acl.cf_waf.arn

  ############################################
  # Enable CloudFront Logging (from logging.tf)
  ############################################
  logging_config {
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    include_cookies = false
    prefix          = "cloudfront-logs/"
  }

  ############################################
  # Restrictions
  ############################################
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  ############################################
  # SSL Certificate
  ############################################
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
