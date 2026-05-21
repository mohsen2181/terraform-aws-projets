resource "aws_customer_gateway" "onprem" {
  bgp_asn    = 65000
  ip_address = aws_eip.onprem_customer_gateway.public_ip
  type       = "ipsec.1"

  tags = {
    Name = "On-Premises Customer Gateway"
  }
}

resource "aws_vpn_connection" "onprem_to_tgw" {
  customer_gateway_id = aws_customer_gateway.onprem.id
  transit_gateway_id  = aws_ec2_transit_gateway.main.id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name = "On-Premises-to-TGW-VPN"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "vpn" {
  transit_gateway_attachment_id  = aws_vpn_connection.onprem_to_tgw.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

# Propagation was missing: without this the TGW route table does not learn
# the on-prem CIDR dynamically. The static aws_ec2_transit_gateway_route
# below covers the on-prem → cloud direction, but adding propagation here
# keeps the table consistent and future-proof (e.g. if you add BGP later).
resource "aws_ec2_transit_gateway_route_table_propagation" "vpn" {
  transit_gateway_attachment_id  = aws_vpn_connection.onprem_to_tgw.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route" "to_onprem" {
  destination_cidr_block         = var.onprem_vpc_cidr
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
  transit_gateway_attachment_id  = aws_vpn_connection.onprem_to_tgw.transit_gateway_attachment_id

  depends_on = [
    aws_ec2_transit_gateway_route_table_association.vpn
  ]
}

locals {
  cloud_vpc_cidrs = [
    "10.0.0.0/16",
    "10.1.0.0/16",
    "10.2.0.0/16"
  ]
}

resource "aws_route" "onprem_private_to_cloud_vpcs" {
  for_each = toset(local.cloud_vpc_cidrs)

  route_table_id         = aws_route_table.onprem_private.id
  destination_cidr_block = each.value
  network_interface_id   = aws_instance.onprem_customer_gateway.primary_network_interface_id
}

resource "aws_route" "cloud_private_to_onprem" {
  for_each = {
    for item in flatten([
      for vpc_key, vpc in module.vpc : [
        for rt_index, rt_id in vpc.private_route_table_ids : {
          key            = "${vpc_key}-private-rt-${rt_index}-to-onprem"
          route_table_id = rt_id
        }
      ]
    ]) : item.key => item
  }

  route_table_id         = each.value.route_table_id
  destination_cidr_block = var.onprem_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [
    aws_ec2_transit_gateway_route.to_onprem
  ]
}

