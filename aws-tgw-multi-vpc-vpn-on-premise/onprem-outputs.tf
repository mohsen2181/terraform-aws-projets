output "onprem_vpc_id" {
  value = aws_vpc.onprem.id
}

output "onprem_vpc_cidr" {
  value = aws_vpc.onprem.cidr_block
}

output "onprem_public_subnet_id" {
  value = aws_subnet.onprem_public.id
}

output "onprem_private_subnet_id" {
  value = aws_subnet.onprem_private.id
}

output "onprem_app_server_private_ip" {
  value = aws_instance.onprem_app.private_ip
}

output "onprem_dns_server_private_ip" {
  value = aws_instance.onprem_dns.private_ip
}

output "onprem_customer_gateway_instance_id" {
  value = aws_instance.onprem_customer_gateway.id
}

output "onprem_customer_gateway_private_ip" {
  value = aws_instance.onprem_customer_gateway.private_ip
}

output "onprem_customer_gateway_public_ip" {
  value = aws_eip.onprem_customer_gateway.public_ip
}

output "onprem_customer_gateway_security_group_id" {
  value = aws_security_group.onprem_customer_gateway.id
}
