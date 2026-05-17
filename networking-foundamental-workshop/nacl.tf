# -------------------------
# Custom Network ACL
# -------------------------

resource "aws_network_acl" "vpc_a_nacl" {
  vpc_id = aws_vpc.vpc_a.id

  tags = {
    Name = "VPC-A-NACL"
  }
}

# -------------------------
# Allow ALL inbound traffic
# (default behavior for lab)
# -------------------------

resource "aws_network_acl_rule" "allow_all_inbound" {
  network_acl_id = aws_network_acl.vpc_a_nacl.id

  rule_number = 100
  egress      = false
  protocol    = "-1"
  rule_action = "allow"

  cidr_block = "0.0.0.0/0"

  from_port = 0
  to_port   = 0
}

# -------------------------
# Allow ALL outbound traffic
# -------------------------

resource "aws_network_acl_rule" "allow_all_outbound" {
  network_acl_id = aws_network_acl.vpc_a_nacl.id

  rule_number = 100
  egress      = true
  protocol    = "-1"
  rule_action = "allow"

  cidr_block = "0.0.0.0/0"

  from_port = 0
  to_port   = 0
}

# -------------------------
# Associate NACL to subnets
# -------------------------

resource "aws_network_acl_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  network_acl_id = aws_network_acl.vpc_a_nacl.id
}

resource "aws_network_acl_association" "private_az1" {
  subnet_id      = aws_subnet.private_az1.id
  network_acl_id = aws_network_acl.vpc_a_nacl.id
}

resource "aws_network_acl_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  network_acl_id = aws_network_acl.vpc_a_nacl.id
}

resource "aws_network_acl_association" "private_az3" {
  subnet_id      = aws_subnet.private_az3.id
  network_acl_id = aws_network_acl.vpc_a_nacl.id
}
