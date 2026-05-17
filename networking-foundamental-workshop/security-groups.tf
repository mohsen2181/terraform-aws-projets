# -------------------------
# EC2 Security Group
# Allow All ICMP IPv4
# -------------------------

resource "aws_security_group" "ec2_icmp_sg" {
  name        = "VPC-A-EC2-ICMP-SG"
  description = "Allow all ICMP IPv4 traffic"
  vpc_id      = aws_vpc.vpc_a.id

  ingress {
    description = "Allow all ICMP IPv4"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound IPv4"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "VPC-A-EC2-ICMP-SG"
  }
}
