resource "aws_route53_health_check" "primary" {
  fqdn              = var.primary_health_check_fqdn
  port              = 443
  type              = "HTTPS"
  resource_path     = "/read"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "primary-api-health-check"
  }
}

resource "aws_route53_record" "primary" {
  zone_id = var.zone_id
  name    = var.record_name
  type    = "A"

  set_identifier = "primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary.id

  alias {
    name                   = var.primary_domain_name
    zone_id                = var.primary_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "secondary" {
  zone_id = var.zone_id
  name    = var.record_name
  type    = "A"

  set_identifier = "secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = var.secondary_domain_name
    zone_id                = var.secondary_zone_id
    evaluate_target_health = true
  }
}