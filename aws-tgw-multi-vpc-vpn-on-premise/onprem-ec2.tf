data "aws_ssm_parameter" "al2023_onprem" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

data "aws_ssm_parameter" "amzn2_onprem" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "onprem_app" {
  ami                    = data.aws_ssm_parameter.al2023_onprem.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.onprem_private.id
  private_ip             = "172.16.1.100"
  iam_instance_profile   = aws_iam_instance_profile.ssm[0].name
  vpc_security_group_ids = [aws_security_group.onprem_app.id]

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    echo "Hello from On-Premises App Server" > /var/www/html/index.html
    systemctl enable httpd
    systemctl start httpd
  EOF

  tags = {
    Name = "On-Premises App Server"
  }

  depends_on = [
    aws_route.onprem_private_default_nat
  ]
}

resource "aws_instance" "onprem_dns" {
  ami                    = data.aws_ssm_parameter.al2023_onprem.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.onprem_private.id
  private_ip             = "172.16.1.200"
  iam_instance_profile   = aws_iam_instance_profile.ssm[0].name
  vpc_security_group_ids = [aws_security_group.onprem_dns.id]

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y bind bind-utils

    APPIP=172.16.1.100
    MYIP=172.16.1.200

    cat > /etc/named.conf << 'NAMEDCONF'
    options {
      directory "/var/named";
      recursion yes;
      allow-query { any; };
      dnssec-validation no;

      forwarders {
        169.254.169.253;
      };

      forward first;
    };

    zone "example.corp" IN {
      type master;
      file "/etc/named/example.corp";
      allow-update { none; };
    };
    NAMEDCONF

    cat > /etc/named/example.corp << EOFZONE
    $TTL 60
    @ IN SOA ns1.example.corp. admin.example.corp. (
      2025052001
      3600
      600
      604800
      1800
    )

    @     IN NS ns1.example.corp.
    myapp IN A  $APPIP
    ns1   IN A  $MYIP
    EOFZONE

    chown root:named /etc/named/example.corp
    chmod 640 /etc/named/example.corp

    systemctl enable named
    systemctl start named
  EOF

  tags = {
    Name = "On-Premises DNS Server"
  }

  depends_on = [
    aws_instance.onprem_app
  ]
}

resource "aws_eip" "onprem_customer_gateway" {
  domain = "vpc"

  tags = {
    Name = "On-Premises Customer Gateway EIP"
  }
}

resource "aws_instance" "onprem_customer_gateway" {
  ami                    = data.aws_ssm_parameter.amzn2_onprem.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.onprem_public.id
  private_ip             = "172.16.0.100"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ssm[0].name
  vpc_security_group_ids = [aws_security_group.onprem_customer_gateway.id]

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    yum install -y openswan
    systemctl enable ipsec

    cat >> /etc/sysctl.conf << EOFCONF
    net.ipv4.ip_forward = 1
    net.ipv4.conf.default.rp_filter = 0
    net.ipv4.conf.default.accept_source_route = 0
    EOFCONF

    sysctl -p
  EOF

  tags = {
    Name = "On-Premises Customer Gateway"
  }

  depends_on = [
    aws_route.onprem_public_default
  ]
}

resource "aws_eip_association" "onprem_customer_gateway" {
  allocation_id = aws_eip.onprem_customer_gateway.id
  instance_id   = aws_instance.onprem_customer_gateway.id
}
