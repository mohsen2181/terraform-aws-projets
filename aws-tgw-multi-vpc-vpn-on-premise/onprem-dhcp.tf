

resource "aws_vpc_dhcp_options" "onprem" {
  domain_name = "${var.aws_region}.compute.internal"

  domain_name_servers = [
    "AmazonProvidedDNS"
  ]

  tags = {
    Name = "On-Premises DHCP Options"
  }
}

resource "aws_vpc_dhcp_options_association" "onprem" {
  vpc_id          = aws_vpc.onprem.id
  dhcp_options_id = aws_vpc_dhcp_options.onprem.id
}
