############################################
# WAF IP Set (block specific IPs)
############################################
resource "aws_wafv2_ip_set" "blocked_ips" {
  provider = aws.us_east_1

  name               = "blocked-ips"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"

  addresses = [
    #"176.147.243.147/32" 
    "176.147.243.100/32" # replace with real IP if needed */
  ]
}

############################################
# WAF Web ACL
############################################
resource "aws_wafv2_web_acl" "cf_waf" {
  provider = aws.us_east_1

  name  = "cloudfront-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cf-waf"
    sampled_requests_enabled   = true
  }

  ############################################
  # 🚫 Block IP rule
  ############################################
  rule {
    name     = "BlockBadIPs"
    priority = 1

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blocked_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "block-ips"
      sampled_requests_enabled   = true
    }
  }

  ############################################
  # 🚦 Rate limiting rule
  ############################################
  rule {
    name     = "RateLimit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 20 # requests per 5 minutes per IP
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit"
      sampled_requests_enabled   = true
    }
  }

  ############################################
  # ✅ AWS Managed Rules
  # 👉 This includes internal rules like: CrossSiteScripting_QUERYSTRING and CrossSiteScripting_BODY
  ############################################
  rule {
    name     = "AWSManagedCommonRules"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common-rules"
      sampled_requests_enabled   = true
    }
  }

  ############################################
  # 🚦 SQL injection  rule
  ############################################
  rule {
    name     = "SQLiProtection"
    priority = 4

    action {
      block {}
    }

    statement {
      sqli_match_statement {
        field_to_match {
          query_string {}
        }

        text_transformation {
          priority = 0
          type     = "URL_DECODE"
        }

        text_transformation {
          priority = 1
          type     = "LOWERCASE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "sqli-detection"
      sampled_requests_enabled   = true
    }
  }

}
