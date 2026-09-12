# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2 SSM
resource "aws_iam_role" "ec2_role" {
  name = "web-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "web-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# Render user_data template with MySQL connection endpoint
locals {
  user_data_rendered = templatefile("${path.module}/user_data.sh.tpl", {
    db_endpoint = aws_db_instance.mysql_db.address
    db_username = var.db_username
    db_password = var.db_password
    db_name     = var.db_name
  })
}

# Web Server 1 in Private Subnet AZ 1 (10.10.13.0/24)
resource "aws_instance" "web_server_1" {
  ami                  = data.aws_ami.amazon_linux_2023.id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.web_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name             = var.key_name

  user_data = local.user_data_rendered

  tags = {
    Name = "web-server-az1"
  }

  depends_on = [
    aws_vpc_endpoint.s3,
    aws_db_instance.mysql_db
  ]
}

# Web Server 2 in Private Subnet AZ 2 (10.10.14.0/24)
resource "aws_instance" "web_server_2" {
  ami                  = data.aws_ami.amazon_linux_2023.id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.web_2.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name             = var.key_name

  user_data = local.user_data_rendered

  tags = {
    Name = "web-server-az2"
  }

  depends_on = [
    aws_vpc_endpoint.s3,
    aws_db_instance.mysql_db
  ]
}
