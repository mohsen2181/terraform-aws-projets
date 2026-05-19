data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  vpc_definitions = {
    a = {
      name            = "${var.project_name}-vpc-a"
      cidr            = "10.0.0.0/16"
      public_subnets  = ["10.0.0.0/24", "10.0.2.0/24"]
      private_subnets = ["10.0.1.0/24", "10.0.3.0/24"]
      tgw_subnets     = ["10.0.5.0/28", "10.0.5.16/28"]
    }
    b = {
      name            = "${var.project_name}-vpc-b"
      cidr            = "10.1.0.0/16"
      public_subnets  = ["10.1.0.0/24", "10.1.2.0/24"]
      private_subnets = ["10.1.1.0/24", "10.1.3.0/24"]
      tgw_subnets     = ["10.1.5.0/28", "10.1.5.16/28"]
    }
    c = {
      name            = "${var.project_name}-vpc-c"
      cidr            = "10.2.0.0/16"
      public_subnets  = ["10.2.0.0/24", "10.2.2.0/24"]
      private_subnets = ["10.2.1.0/24", "10.2.3.0/24"]
      tgw_subnets     = ["10.2.5.0/28", "10.2.5.16/28"]
    }
  }
}

module "vpc" {
  for_each = local.vpc_definitions
  source   = "./modules/vpc"

  name            = each.value.name
  cidr            = each.value.cidr
  azs             = local.azs
  public_subnets  = each.value.public_subnets
  private_subnets = each.value.private_subnets
  tgw_subnets     = each.value.tgw_subnets

  allowed_internal_cidrs = [
    local.vpc_definitions.a.cidr,
    local.vpc_definitions.b.cidr,
    local.vpc_definitions.c.cidr
  ]
}

resource "aws_ec2_transit_gateway" "main" {
  description                     = "${var.project_name} transit gateway"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = "${var.project_name}-tgw"
  }
}

resource "aws_ec2_transit_gateway_route_table" "main" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "${var.project_name}-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = module.vpc

  vpc_id             = each.value.vpc_id
  subnet_ids         = each.value.tgw_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "${each.value.name}-tgw-attachment"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = aws_ec2_transit_gateway_vpc_attachment.this

  transit_gateway_attachment_id  = each.value.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = aws_ec2_transit_gateway_vpc_attachment.this

  transit_gateway_attachment_id  = each.value.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

locals {
  # Static keys: source VPC, destination VPC, and private route table index.
  # Dynamic AWS-created route table IDs are kept only as values.
  vpc_routes = merge([
    for source_key, source_vpc in local.vpc_definitions : merge([
      for dest_key, dest_vpc in local.vpc_definitions : {
        for rt_index in range(length(source_vpc.private_subnets)) :
        "${source_key}-to-${dest_key}-private-rt-${rt_index}" => {
          route_table_id   = module.vpc[source_key].private_route_table_ids[rt_index]
          destination_cidr = dest_vpc.cidr
        }
      } if source_key != dest_key
    ]...)
  ]...)
}

resource "aws_route" "private_to_tgw" {
  for_each = local.vpc_routes

  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.destination_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.this,
    aws_ec2_transit_gateway_route_table_association.this,
    aws_ec2_transit_gateway_route_table_propagation.this
  ]
}
