# -------------------------
# Security Group for Interface Endpoints
# -------------------------

resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "VPC-A-Endpoint-SG"
  description = "Allow HTTPS from VPC to interface endpoints"
  vpc_id      = aws_vpc.vpc_a.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "VPC-A-Endpoint-SG"
  }
}

# -------------------------
# KMS Interface Endpoint
# -------------------------

resource "aws_vpc_endpoint" "kms" {
  vpc_id              = aws_vpc.vpc_a.id
  service_name        = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_az1.id, aws_subnet.private_az3.id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "VPC-A-KMS-Interface-Endpoint"
  }
}

# -------------------------
# S3 Gateway Endpoint
# -------------------------

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc_a.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.public.id,
    aws_route_table.private.id
  ]

  tags = {
    Name = "VPC-A-S3-Gateway-Endpoint"
  }
}


resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.vpc_a.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_az1.id, aws_subnet.private_az3.id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "VPC-A-SSM-Endpoint"
  }
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = aws_vpc.vpc_a.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_az1.id, aws_subnet.private_az3.id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "VPC-A-SSM-Messages-Endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = aws_vpc.vpc_a.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_az1.id, aws_subnet.private_az3.id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "VPC-A-EC2-Messages-Endpoint"
  }
}
