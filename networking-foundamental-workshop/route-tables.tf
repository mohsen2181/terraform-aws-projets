# -------------------------
# Internet Gateway
# -------------------------

resource "aws_internet_gateway" "vpc_a_igw" {
  vpc_id = aws_vpc.vpc_a.id

  tags = {
    Name = "VPC-A-IGW"
  }
}

# -------------------------
# Public Route Table
# -------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc_a.id

  tags = {
    Name = "VPC-A-Public-RT"
  }
}

resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_a_igw.id
}

resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# NAT Gateway
# -------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "VPC-A-NAT-EIP"
  }
}

resource "aws_nat_gateway" "vpc_a_nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_az1.id

  tags = {
    Name = "VPC-A-NAT-GW"
  }

  depends_on = [aws_internet_gateway.vpc_a_igw]
}

# -------------------------
# Private Route Table
# -------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc_a.id

  tags = {
    Name = "VPC-A-Private-RT"
  }
}

resource "aws_route" "private_default_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.vpc_a_nat.id
}

resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_az3" {
  subnet_id      = aws_subnet.private_az3.id
  route_table_id = aws_route_table.private.id
}
