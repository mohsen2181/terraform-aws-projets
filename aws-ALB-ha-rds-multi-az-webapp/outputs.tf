output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web_alb.dns_name
}

output "website_https_url" {
  description = "Secure HTTPS Website URL"
  value       = "https://${var.domain_name}"
}

output "acm_certificate_arn" {
  description = "ARN of the validated ACM SSL Certificate"
  value       = aws_acm_certificate_validation.cert.certificate_arn
}

output "rds_endpoint" {
  description = "Multi-AZ MySQL RDS Endpoint"
  value       = aws_db_instance.mysql_db.endpoint
}

output "web_server_1_private_ip" {
  description = "Private IP of Web Server 1 in AZ 1"
  value       = aws_instance.web_server_1.private_ip
}

output "web_server_2_private_ip" {
  description = "Private IP of Web Server 2 in AZ 2"
  value       = aws_instance.web_server_2.private_ip
}

output "route53_zone_id" {
  description = "The ID of the referenced Route 53 Hosted Zone"
  value       = data.aws_route53_zone.primary.zone_id
}

output "route53_name_servers" {
  description = "The Name Servers (NS) of your persistent Route 53 Hosted Zone"
  value       = data.aws_route53_zone.primary.name_servers
}
