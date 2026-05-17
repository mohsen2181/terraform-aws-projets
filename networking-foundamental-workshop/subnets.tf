# -------------------------
# Public Subnet - AZ1
# -------------------------

resource "aws_subnet" "public_az1" {
  vpc_id            = aws_vpc.vpc_a.id
  cidr_block        = var.public_subnet_az1_cidr
  availability_zone = local.az1

  map_public_ip_on_launch = true

  tags = {
    Name = "VPC-A-Public-Subnet-AZ1"
  }
}

# -------------------------
# Private Subnet - AZ1
# -------------------------

resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.vpc_a.id
  cidr_block        = var.private_subnet_az1_cidr
  availability_zone = local.az1

  map_public_ip_on_launch = false

  tags = {
    Name = "VPC-A-Private-Subnet-AZ1"
  }
}

# -------------------------
# Public Subnet - AZ2
# -------------------------

resource "aws_subnet" "public_az2" {
  vpc_id            = aws_vpc.vpc_a.id
  cidr_block        = var.public_subnet_az2_cidr
  availability_zone = local.az2

  map_public_ip_on_launch = true

  tags = {
    Name = "VPC-A-Public-Subnet-AZ2"
  }
}

# -------------------------
# Private Subnet - AZ3
# -------------------------

resource "aws_subnet" "private_az3" {
  vpc_id            = aws_vpc.vpc_a.id
  cidr_block        = var.private_subnet_az3_cidr
  availability_zone = local.az3

  map_public_ip_on_launch = false

  tags = {
    Name = "VPC-A-Private-Subnet-AZ3"
  }
}
