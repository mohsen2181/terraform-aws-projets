resource "aws_security_group" "onprem_app" {
  name        = "On-Premises App Server Security Group"
  description = "Security group for on-premises app server"
  vpc_id      = aws_vpc.onprem.id

  ingress {
    description = "HTTP from AWS private ranges"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16"
    ]
  }

  ingress {
    description = "ICMP from private ranges and participant IP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
      var.participant_ip_address
    ]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "onprem_dns" {
  name        = "On-Premises DNS Server Security Group"
  description = "Security group for on-premises DNS server"
  vpc_id      = aws_vpc.onprem.id

  ingress {
    description = "DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16"
    ]
  }

  ingress {
    description = "DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16"
    ]
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
      var.participant_ip_address
    ]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "onprem_customer_gateway" {
  name        = "On-Premises Customer Gateway Security Group"
  description = "Security group for on-premises customer gateway"
  vpc_id      = aws_vpc.onprem.id

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
      var.participant_ip_address
    ]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "IPsec IKE from AWS tunnel 1"
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["13.38.212.82/32"]
  }

  ingress {
    description = "IPsec NAT-T from AWS tunnel 1"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["13.38.212.82/32"]
  }

  ingress {
    description = "ESP from AWS tunnel 1"
    from_port   = 0
    to_port     = 0
    protocol    = "50"
    cidr_blocks = ["13.38.212.82/32"]
  }

  ingress {
    description = "IPsec IKE from AWS tunnel 2"
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["15.224.92.217/32"]
  }

  ingress {
    description = "IPsec NAT-T from AWS tunnel 2"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["15.224.92.217/32"]
  }

  ingress {
    description = "ESP from AWS tunnel 2"
    from_port   = 0
    to_port     = 0
    protocol    = "50"
    cidr_blocks = ["15.224.92.217/32"]
  }
}
