resource "aws_security_group" "vpc_endpoints" {
  for_each = module.vpc

  name        = "${each.value.name}-vpce-sg"
  description = "Security group for VPC interface endpoints"
  vpc_id      = each.value.vpc_id

  ingress {
    description = "HTTPS from internal VPC CIDRs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    cidr_blocks = [
      "10.0.0.0/16",
      "10.1.0.0/16",
      "10.2.0.0/16"
    ]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${each.value.name}-vpce-sg"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = module.vpc

  vpc_id              = each.value.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = each.value.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[each.key].id]

  tags = {
    Name = "${each.value.name}-ssm-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  for_each = module.vpc

  vpc_id              = each.value.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = each.value.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[each.key].id]

  tags = {
    Name = "${each.value.name}-ssmmessages-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  for_each = module.vpc

  vpc_id              = each.value.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = each.value.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[each.key].id]

  tags = {
    Name = "${each.value.name}-ec2messages-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2" {
  for_each = module.vpc

  vpc_id              = each.value.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = each.value.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[each.key].id]

  tags = {
    Name = "${each.value.name}-ec2-endpoint"
  }
}

resource "aws_vpc_endpoint" "s3" {
  for_each = module.vpc

  vpc_id            = each.value.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = each.value.private_route_table_ids

  tags = {
    Name = "${each.value.name}-s3-endpoint"
  }
}
