# -------------------------
# Amazon Linux 2023 AMI
# -------------------------

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# -------------------------
# Public EC2 - AZ2
# -------------------------

resource "aws_instance" "public_az2" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_az2.id
  private_ip                  = var.public_instance_private_ip
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.ec2_icmp_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  tags = {
    Name = "VPC-A-Public-EC2-AZ2"
  }
}

# -------------------------
# Private EC2 - AZ1
# -------------------------

resource "aws_instance" "private_az1" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_az1.id
  private_ip                  = var.private_instance_private_ip
  associate_public_ip_address = false

  vpc_security_group_ids = [
    aws_security_group.ec2_icmp_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  tags = {
    Name = "VPC-A-Private-EC2-AZ1"
  }
}
