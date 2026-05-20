resource "aws_iam_role" "ssm" {
  count = var.enable_test_instances ? 1 : 0
  name  = "${var.project_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ssm-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.enable_test_instances ? 1 : 0
  role       = aws_iam_role.ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  count = var.enable_test_instances ? 1 : 0
  name  = "${var.project_name}-ssm-instance-profile"
  role  = aws_iam_role.ssm[0].name
}

resource "aws_instance" "test" {
  for_each = var.enable_test_instances ? module.vpc : {}

  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = each.value.private_subnet_ids[0]
  vpc_security_group_ids      = [each.value.private_security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.ssm[0].name
  associate_public_ip_address = false

  user_data_replace_on_change = true

  user_data = <<-EOF
  #!/bin/bash
  dnf install -y https://s3.${var.aws_region}.amazonaws.com/amazon-ssm-${var.aws_region}/latest/linux_amd64/amazon-ssm-agent.rpm

  systemctl enable amazon-ssm-agent
  systemctl restart amazon-ssm-agent

  nohup python3 -m http.server 8080 --bind 0.0.0.0 > /tmp/http-server.log 2>&1 &
EOF

  tags = {
    Name = "${each.value.name}-test-instance"
  }
}
