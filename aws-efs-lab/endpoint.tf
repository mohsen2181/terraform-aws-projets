resource "aws_security_group" "endpoint_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "endpoint-sg"
  }
}

# =========================
# VPC Endpoints for SSM
# =========================

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.main.id
  vpc_endpoint_type = "Interface"

  service_name = "com.amazonaws.eu-west-3.ssm"

  subnet_ids = aws_subnet.subnets[*].id

  security_group_ids = [aws_security_group.endpoint_sg.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = aws_vpc.main.id
  vpc_endpoint_type = "Interface"

  service_name = "com.amazonaws.eu-west-3.ec2messages"

  subnet_ids = aws_subnet.subnets[*].id

  security_group_ids = [aws_security_group.endpoint_sg.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.main.id
  vpc_endpoint_type = "Interface"

  service_name = "com.amazonaws.eu-west-3.ssmmessages"

  subnet_ids = aws_subnet.subnets[*].id

  security_group_ids = [aws_security_group.endpoint_sg.id]

  private_dns_enabled = true
}
