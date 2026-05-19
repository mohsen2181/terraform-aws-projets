output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.main.id
}

output "transit_gateway_route_table_id" {
  value = aws_ec2_transit_gateway_route_table.main.id
}

output "vpcs" {
  value = {
    for key, vpc in module.vpc : key => {
      name                    = vpc.name
      vpc_id                  = vpc.vpc_id
      public_subnet_ids       = vpc.public_subnet_ids
      private_subnet_ids      = vpc.private_subnet_ids
      tgw_subnet_ids          = vpc.tgw_subnet_ids
      private_route_table_ids = vpc.private_route_table_ids
    }
  }
}

output "test_instances" {
  value = {
    for key, instance in aws_instance.test : key => {
      id         = instance.id
      private_ip = instance.private_ip
    }
  }
}
