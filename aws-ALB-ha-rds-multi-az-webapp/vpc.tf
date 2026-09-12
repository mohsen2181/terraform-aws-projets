# Fetch available AZs in the configured region
data "aws_availability_zones" "available" {
  state = "available"
}

# 1. Main VPC (10.10.0.0/16)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

# 2. Internet Gateway (for ALB in public subnets)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# 3. Public Subnets (for ALB)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-az1 (10.10.0.0/24)"
    Type = "Public"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-az2 (10.10.1.0/24)"
    Type = "Public"
  }
}

# 4. Private Subnets for Web Servers
resource "aws_subnet" "web_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.web_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "private-web-subnet-az1 (10.10.13.0/24)"
    Type = "Private-Web"
  }
}

resource "aws_subnet" "web_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.web_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "private-web-subnet-az2 (10.10.14.0/24)"
    Type = "Private-Web"
  }
}

# 5. Private Subnets for MySQL RDS
resource "aws_subnet" "db_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "private-db-subnet-az1 (10.10.11.0/24)"
    Type = "Private-DB"
  }
}

resource "aws_subnet" "db_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "private-db-subnet-az2 (10.10.12.0/24)"
    Type = "Private-DB"
  }
}

# 6. S3 Gateway VPC Endpoint (100% Free - enables private EC2 instances to download AL2023 packages via internal AWS network)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_web.id]

  tags = {
    Name = "s3-gateway-endpoint"
  }
}

# 7. Route Tables
# Public Route Table (via IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Private Route Table for Web Tier (isolated from internet, routed to S3 Endpoint)
resource "aws_route_table" "private_web" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-web-route-table"
  }
}

# Private Route Table for DB Tier (completely isolated)
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-db-isolated-route-table"
  }
}

# 8. Route Table Associations
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "web_1" {
  subnet_id      = aws_subnet.web_1.id
  route_table_id = aws_route_table.private_web.id
}

resource "aws_route_table_association" "web_2" {
  subnet_id      = aws_subnet.web_2.id
  route_table_id = aws_route_table.private_web.id
}

resource "aws_route_table_association" "db_1" {
  subnet_id      = aws_subnet.db_1.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_route_table_association" "db_2" {
  subnet_id      = aws_subnet.db_2.id
  route_table_id = aws_route_table.private_db.id
}
