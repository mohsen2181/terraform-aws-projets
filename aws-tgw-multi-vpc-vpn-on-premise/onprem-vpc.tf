resource "aws_vpc" "onprem" {
  cidr_block           = var.onprem_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "On Premises"
  }
}

resource "aws_subnet" "onprem_public" {
  vpc_id                  = aws_vpc.onprem.id
  cidr_block              = var.onprem_public_subnet_cidr
  availability_zone       = local.azs[0]
  map_public_ip_on_launch = false

  tags = {
    Name       = "On-Premises Public Subnet"
    SubnetType = "Public"
  }
}

resource "aws_subnet" "onprem_private" {
  vpc_id                  = aws_vpc.onprem.id
  cidr_block              = var.onprem_private_subnet_cidr
  availability_zone       = local.azs[0]
  map_public_ip_on_launch = false

  tags = {
    Name       = "On-Premises Private Subnet"
    SubnetType = "Private"
  }
}

resource "aws_internet_gateway" "onprem" {
  vpc_id = aws_vpc.onprem.id

  tags = {
    Name = "On-Premises IGW"
  }
}

resource "aws_route_table" "onprem_public" {
  vpc_id = aws_vpc.onprem.id

  tags = {
    Name    = "On-Premises Public Route Table"
    Network = "Public"
  }
}

resource "aws_route" "onprem_public_default" {
  route_table_id         = aws_route_table.onprem_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.onprem.id
}

resource "aws_route_table_association" "onprem_public" {
  subnet_id      = aws_subnet.onprem_public.id
  route_table_id = aws_route_table.onprem_public.id
}

resource "aws_eip" "onprem_nat" {
  domain = "vpc"

  tags = {
    Name = "On-Premises NAT EIP"
  }
}

resource "aws_nat_gateway" "onprem" {
  allocation_id = aws_eip.onprem_nat.id
  subnet_id     = aws_subnet.onprem_public.id

  tags = {
    Name = "On-Premises NATGW"
  }

  depends_on = [
    aws_internet_gateway.onprem
  ]
}

resource "aws_route_table" "onprem_private" {
  vpc_id = aws_vpc.onprem.id

  tags = {
    Name    = "On-Premises Private Route Table"
    Network = "Private"
  }
}

resource "aws_route" "onprem_private_default_nat" {
  route_table_id         = aws_route_table.onprem_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.onprem.id
}

resource "aws_route_table_association" "onprem_private" {
  subnet_id      = aws_subnet.onprem_private.id
  route_table_id = aws_route_table.onprem_private.id
}
