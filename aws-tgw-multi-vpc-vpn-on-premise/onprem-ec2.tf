data "aws_ssm_parameter" "al2023_onprem" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

resource "aws_instance" "onprem_app" {
  ami                    = trimspace(data.aws_ssm_parameter.al2023_onprem.value)
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
  ami                    = trimspace(data.aws_ssm_parameter.al2023_onprem.value)
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
  ami                    = trimspace(data.aws_ssm_parameter.al2023_onprem.value)
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.onprem_public.id
  private_ip             = "172.16.0.100"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ssm[0].name
  vpc_security_group_ids = [aws_security_group.onprem_customer_gateway.id]

  user_data_replace_on_change = true

  user_data = <<-EOF
#!/bin/bash
set -eux

# The VPC resolver (169.254.169.253 / the .2 address of the VPC CIDR) already
# handles both public DNS and AWS endpoint resolution — do NOT override
# resolv.conf here. Pointing at 172.16.1.200 (the on-prem DNS instance)
# would break SSM permanently because that instance may not be up yet and
# cannot resolve ssm.amazonaws.com endpoints anyway.

systemctl enable amazon-ssm-agent || true
systemctl restart amazon-ssm-agent || true

# Wait until the EIP gives this instance internet access before proceeding
# with libreswan/iptables installation.
for i in {1..60}; do
  if curl -s --connect-timeout 3 https://ssm.${var.aws_region}.amazonaws.com >/dev/null; then
    break
  fi
  sleep 5
done

dnf install -y libreswan iptables-services

CGW_PUBLIC_IP="${aws_eip.onprem_customer_gateway.public_ip}"

TUNNEL1_OUTSIDE_IP="${aws_vpn_connection.onprem_to_tgw.tunnel1_address}"
TUNNEL2_OUTSIDE_IP="${aws_vpn_connection.onprem_to_tgw.tunnel2_address}"

TUNNEL1_PSK="${aws_vpn_connection.onprem_to_tgw.tunnel1_preshared_key}"
TUNNEL2_PSK="${aws_vpn_connection.onprem_to_tgw.tunnel2_preshared_key}"

# Kernel settings required for IPsec forwarding
cat > /etc/sysctl.d/99-ipsec-forwarding.conf <<SYSCTL
net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
SYSCTL
sysctl --system

cat > /etc/ipsec.conf <<IPSECCONF
config setup
    uniqueids=no

conn %default
    authby=secret
    type=tunnel
    ike=aes128-sha1;modp2048
    phase2alg=aes128-sha1;modp2048
    ikelifetime=8h
    salifetime=1h
    pfs=yes
    keyingtries=%forever
    dpddelay=10
    dpdtimeout=30
    dpdaction=restart
    left=172.16.0.100
    leftid=$CGW_PUBLIC_IP
    leftsubnet=172.16.0.0/16

# tunnel-2 is the active tunnel carrying all three cloud VPC CIDRs (10.0.0.0/8).
# tunnel-1 is loaded but not auto-started (hot standby).
# Both tunnels use the same rightsubnet — AWS replies symmetrically on the
# same tunnel it receives on, so keeping one active avoids asymmetric routing.
conn aws-tunnel-2
    right=$TUNNEL2_OUTSIDE_IP
    rightid=$TUNNEL2_OUTSIDE_IP
    rightsubnet=10.0.0.0/8
    auto=start

conn aws-tunnel-1
    right=$TUNNEL1_OUTSIDE_IP
    rightid=$TUNNEL1_OUTSIDE_IP
    rightsubnet=10.0.0.0/8
    auto=add
IPSECCONF

cat > /etc/ipsec.secrets <<SECRETS
$CGW_PUBLIC_IP $TUNNEL1_OUTSIDE_IP : PSK "$TUNNEL1_PSK"
$CGW_PUBLIC_IP $TUNNEL2_OUTSIDE_IP : PSK "$TUNNEL2_PSK"
SECRETS
chmod 600 /etc/ipsec.secrets

# Allow forwarding between on-prem and cloud VPCs
iptables -A FORWARD -s 172.16.0.0/16 -d 10.0.0.0/8 -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/8 -d 172.16.0.0/16 -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

service iptables save
systemctl enable iptables
systemctl restart iptables

systemctl enable ipsec
systemctl restart ipsec

sleep 10

ipsec auto --up aws-tunnel-1 || true
ipsec auto --up aws-tunnel-2 || true

ipsec status
EOF

  tags = {
    Name = "On-Premises Customer Gateway"
  }

  depends_on = [
    aws_route.onprem_public_default,
    aws_vpn_connection.onprem_to_tgw
  ]
}


resource "aws_eip_association" "onprem_customer_gateway" {
  allocation_id = aws_eip.onprem_customer_gateway.id
  instance_id   = aws_instance.onprem_customer_gateway.id
}
