# Hybrid Cloud Testing Notes

This document contains all commands required to validate the **AWS Transit Gateway + Site-to-Site VPN + Hybrid Cloud connectivity** between AWS VPCs and the simulated on-premises environment.

---

# Environment Outputs

## AWS Cloud

### Transit Gateway

```text
Transit Gateway ID: tgw-09e44f8db36cdd76e
Transit Gateway Route Table: tgw-rtb-0960c058dff357a4e
```

---

### Cloud Test Instances

| VPC | Instance ID | Private IP |
|------|-------------|-------------|
| VPC A | `i-0e3b408a3d503e74e` | `10.0.1.85` |
| VPC B | `i-032fff049ccf4bc99` | `10.1.1.133` |
| VPC C | `i-0524314c98f0a11ee` | `10.2.1.234` |

---

## On-Premises Environment

| Component | Value |
|------------|-------|
| On-Prem VPC | `vpc-0eba28ac6fccdb8f5` |
| CIDR | `172.16.0.0/16` |
| Customer Gateway EC2 | `i-0def77278bee4ead6` |
| Customer Gateway Private IP | `172.16.0.100` |
| Customer Gateway Public IP | `35.181.179.233` |
| App Server | `172.16.1.100` |
| DNS Server | `172.16.1.200` |

---

# 1. Validate Customer Gateway

Verify AWS Customer Gateway:

```bash
aws ec2 describe-customer-gateways \
  --region eu-west-3 \
  --output table
```

Expected:

```text
State = available
```

---

# 2. Validate VPN Connection

Check VPN connection:

```bash
aws ec2 describe-vpn-connections \
  --region eu-west-3 \
  --query 'VpnConnections[*].[VpnConnectionId,State,Type,CustomerGatewayId,TransitGatewayId]' \
  --output table
```

Expected:

```text
available
```

Example:

```text
vpn-03db02f978c2b47e7
```

---

# 3. Validate VPN Tunnel Status

Verify tunnel telemetry:

```bash
aws ec2 describe-vpn-connections \
  --vpn-connection-ids vpn-03db02f978c2b47e7 \
  --region eu-west-3 \
  --query 'VpnConnections[0].VgwTelemetry[*].[OutsideIpAddress,Status,StatusMessage]' \
  --output table
```

Expected:

```text
13.38.212.82   UP
15.224.92.217  DOWN
```

At least **one tunnel must be UP**.

---

# 4. Validate Transit Gateway VPN Attachment

Check VPN attachment to Transit Gateway:

```bash
aws ec2 describe-transit-gateway-attachments \
  --region eu-west-3 \
  --filters "Name=resource-type,Values=vpn" \
  --query 'TransitGatewayAttachments[*].[TransitGatewayAttachmentId,ResourceId,State,Association.TransitGatewayRouteTableId]' \
  --output table
```

Expected:

```text
available
```

Associated with:

```text
tgw-rtb-0960c058dff357a4e
```

---

# 5. Validate Transit Gateway Route to On-Prem

Verify TGW route:

```bash
aws ec2 search-transit-gateway-routes \
  --region eu-west-3 \
  --transit-gateway-route-table-id tgw-rtb-0960c058dff357a4e \
  --filters Name=route-search.exact-match,Values=172.16.0.0/16 \
  --output table
```

Expected:

```text
172.16.0.0/16
State: active
Type : static
```

---

# 6. Validate Cloud Route Tables

Verify that all cloud VPC private route tables contain:

```text
172.16.0.0/16 → Transit Gateway
```

Example:

```bash
aws ec2 describe-route-tables \
  --region eu-west-3 \
  --route-table-ids \
    rtb-0b8bbd242945cfa6d \
    rtb-027ec6eb99737f328 \
  --query 'RouteTables[*].Routes[*].[DestinationCidrBlock,TransitGatewayId,State]' \
  --output table
```

Expected:

```text
172.16.0.0/16 → tgw-09e44f8db36cdd76e
```

---

# 7. Validate On-Prem Route Table

Verify routes from the on-prem network to AWS cloud CIDRs.

Expected routes:

```text
10.0.0.0/16 → Customer Gateway ENI
10.1.0.0/16 → Customer Gateway ENI
10.2.0.0/16 → Customer Gateway ENI
```

---

# 8. Connect to Customer Gateway EC2

Start SSM session:

```bash
aws ssm start-session \
  --target i-0def77278bee4ead6 \
  --region eu-west-3
```

Verify instance details:

```bash
hostname
cat /etc/resolv.conf

curl -s http://169.254.169.254/latest/meta-data/public-ipv4
curl -s http://169.254.169.254/latest/meta-data/local-ipv4
```

Expected:

```text
Public IP: 35.181.179.233
Private IP: 172.16.0.100
```

---

# 9. Configure OpenSWAN VPN on Customer Gateway

## Create VPN Tunnel Configuration

```bash
sudo tee /etc/ipsec.d/aws-vpn.conf > /dev/null <<'EOF'
conn aws-tunnel-1
  authby=secret
  auto=start
  type=tunnel
  left=%defaultroute
  leftid=35.181.179.233
  leftsubnet=172.16.0.0/16
  right=13.38.212.82
  rightsubnets={10.0.0.0/16,10.1.0.0/16,10.2.0.0/16}
  ike=aes128-sha1;modp1024
  phase2alg=aes128-sha1
  keyingtries=%forever
  ikelifetime=28800s
  salifetime=3600s
  dpddelay=10
  dpdtimeout=30
  dpdaction=restart_by_peer

conn aws-tunnel-2
  authby=secret
  auto=start
  type=tunnel
  left=%defaultroute
  leftid=35.181.179.233
  leftsubnet=172.16.0.0/16
  right=15.224.92.217
  rightsubnets={10.0.0.0/16,10.1.0.0/16,10.2.0.0/16}
  ike=aes128-sha1;modp1024
  phase2alg=aes128-sha1
  keyingtries=%forever
  ikelifetime=28800s
  salifetime=3600s
  dpddelay=10
  dpdtimeout=30
  dpdaction=restart_by_peer
EOF
```

---

## Configure Pre-Shared Keys

```bash
sudo tee /etc/ipsec.d/aws-vpn.secrets > /dev/null <<'EOF'
35.181.179.233 13.38.212.82: PSK "TbD6T0QsM0xphl8NbYamDyTc7bnkg9Ka"
35.181.179.233 15.224.92.217: PSK "usEpxDEH0EOL4.zvlqwaqxQP3IRNp1Nx"
EOF
```

---

## Restart IPsec

Restart OpenSWAN:

```bash
sudo systemctl restart ipsec
```

Check service status:

```bash
sudo systemctl status ipsec --no-pager
```

Check VPN tunnel status:

```bash
sudo ipsec status
```

Detailed tunnel status:

```bash
sudo ipsec auto --status
```

---

## Validate Tunnel Status from AWS

Run from Terraform VM:

```bash
aws ec2 describe-vpn-connections \
  --vpn-connection-ids vpn-03db02f978c2b47e7 \
  --region eu-west-3 \
  --query 'VpnConnections[0].VgwTelemetry[*].[OutsideIpAddress,Status,StatusMessage]' \
  --output table
```

Expected:

```text
13.38.212.82   UP
15.224.92.217  DOWN
```

At least **one tunnel UP** is sufficient.

---

# 10. Validate Cloud → On-Prem Connectivity

## Test from VPC A

Connect:

```bash
aws ssm start-session \
  --target i-0e3b408a3d503e74e \
  --region eu-west-3
```

Ping:

```bash
ping 172.16.1.100 -c 4
```

HTTP:

```bash
curl http://172.16.1.100
```

Expected:

```text
Hello from On-Premises App Server
```

---

## Test from VPC B

Connect:

```bash
aws ssm start-session \
  --target i-032fff049ccf4bc99 \
  --region eu-west-3
```

Ping:

```bash
ping 172.16.1.100 -c 4
```

HTTP:

```bash
curl http://172.16.1.100
```

---

## Test from VPC C

Connect:

```bash
aws ssm start-session \
  --target i-0524314c98f0a11ee \
  --region eu-west-3
```

Ping:

```bash
ping 172.16.1.100 -c 4
```

HTTP:

```bash
curl http://172.16.1.100
```

---

# 11. Validate DNS Resolution

Connect to Customer Gateway:

```bash
aws ssm start-session \
  --target i-0def77278bee4ead6 \
  --region eu-west-3
```

Test DNS:

```bash
dig @172.16.1.200 myapp.example.corp
```

Expected:

```text
172.16.1.100
```

---

# 12. Troubleshooting

## VPN Tunnel DOWN

Check:

```bash
sudo ipsec status
```

Restart:

```bash
sudo systemctl restart ipsec
```

---

## TGW Route in Blackhole State

Cause:

```text
VPN tunnel is DOWN
```

Verify:

```bash
aws ec2 describe-vpn-connections \
  --vpn-connection-ids vpn-03db02f978c2b47e7 \
  --region eu-west-3 \
  --query 'VpnConnections[0].VgwTelemetry[*].[OutsideIpAddress,Status]' \
  --output table
```

---

## Cannot Reach On-Prem App

Verify:

- VPN tunnel UP
- TGW route active
- Cloud route tables updated
- On-prem route table configured
- Security Groups allow ICMP/HTTP

---

# Successful Validation Criteria

The setup is fully operational when:

```text
✓ VPN tunnel is UP
✓ TGW route is active
✓ Cloud EC2 can ping 172.16.1.100
✓ curl returns:
  Hello from On-Premises App Server
✓ DNS resolution works:
  myapp.example.corp
```
```