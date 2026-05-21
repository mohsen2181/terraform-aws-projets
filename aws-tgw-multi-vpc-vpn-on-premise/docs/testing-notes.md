# Hybrid Cloud Testing Notes (Modular Terraform Project)

This document contains all validation and troubleshooting procedures for the Terraform aws project implementing:

- AWS Transit Gateway
- Multi-VPC architecture
- Site-to-Site VPN
- Simulated on-premises environment
- Hybrid DNS
- IPSec HA tunnels
- Private EC2 instances using SSM

---

# Project Architecture


```text
── docs
│   └── testing-notes.md
├── ec2-test.tf
├── main.tf
├── modules
│   └── vpc
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── onprem-dhcp.tf
├── onprem-ec2.tf
├── onprem-endpoints
├── onprem-outputs.tf
├── onprem-security-groups.tf
├── onprem-vpc.tf
├── onprem-vpn.tf
├── outputs.tf
├── provider.tf
├── README.md
├── terraform.tfstate
├── terraform.tfstate.backup
├── terraform.tfvars
├── variables.tf
└── vpc-endpoints.tf
```

---

# Environment Outputs

Retrieve outputs directly from Terraform:

```bash
terraform output
```

Useful outputs:

```bash
terraform output transit_gateway_id
terraform output vpn_connection_id
terraform output cloud_instances
terraform output onprem_instances
terraform output dns_server_ip
```

---

# AWS Region

```text
eu-west-3
```

---

# 1. Validate Terraform Modular Deployment

## Validate Terraform State

```bash
terraform state list
```

Expected module resources:

```text
module.transit_gateway
module.vpn
module.customer_gateway
module.vpc_a
module.vpc_b
module.vpc_c
module.onprem_vpc
module.dns
module.ec2
```

---

## Validate Terraform Outputs

```bash
terraform output
```

Expected:

- Transit Gateway ID
- VPN Connection ID
- EC2 Instance IDs
- DNS Server IP
- Customer Gateway IP

---

# 2. Validate Transit Gateway

## Verify TGW

```bash
aws ec2 describe-transit-gateways \
  --region eu-west-3 \
  --output table
```

Expected:

```text
State = available
```

---

## Validate TGW Attachments

```bash
aws ec2 describe-transit-gateway-attachments \
  --region eu-west-3 \
  --query 'TransitGatewayAttachments[*].[TransitGatewayAttachmentId,ResourceType,State]' \
  --output table
```

Expected attachments:

| Resource Type | Expected |
|---|---|
| vpc | VPC-A |
| vpc | VPC-B |
| vpc | VPC-C |
| vpn | VPN Attachment |

All states should be:

```text
available
```

---

# 3. Validate Customer Gateway

Verify AWS Customer Gateway:

```bash
aws ec2 describe-customer-gateways \
  --region eu-west-3 \
  --output table
```

Expected:

```text
available
```

---

# 4. Validate VPN Connection

## Verify VPN

```bash
aws ec2 describe-vpn-connections \
  --region eu-west-3 \
  --query 'VpnConnections[*].[VpnConnectionId,State,TransitGatewayId]' \
  --output table
```

Expected:

```text
available
```

---

# 5. Validate Both VPN Tunnels

## Tunnel Telemetry

```bash
aws ec2 describe-vpn-connections \
  --region eu-west-3 \
  --query 'VpnConnections[*].VgwTelemetry[*].[OutsideIpAddress,Status,StatusMessage]' \
  --output table
```

Expected:

```text
Tunnel 1 = UP
Tunnel 2 = UP
```

Both tunnels should remain stable.

---

# 6. Validate Transit Gateway Routes

## Verify On-Prem Route

```bash
aws ec2 search-transit-gateway-routes \
  --region eu-west-3 \
  --transit-gateway-route-table-id <TGW-ROUTE-TABLE-ID> \
  --filters Name=route-search.exact-match,Values=172.16.0.0/16 \
  --output table
```

Expected:

```text
State = active
Type  = static
```

---

## Verify Cloud CIDRs

Expected routes:

```text
10.0.0.0/16
10.1.0.0/16
10.2.0.0/16
172.16.0.0/16
```

---

# 7. Validate Cloud Route Tables

Verify cloud route tables contain:

```text
172.16.0.0/16 → Transit Gateway
```

Example:

```bash
aws ec2 describe-route-tables \
  --region eu-west-3 \
  --query 'RouteTables[*].Routes[*].[DestinationCidrBlock,TransitGatewayId,State]' \
  --output table
```

Expected:

```text
172.16.0.0/16 → tgw-xxxxxxxx
```

---

# 8. Validate On-Prem Route Table

Expected routes on on-prem VPC route tables:

```text
10.0.0.0/16
10.1.0.0/16
10.2.0.0/16
```

Target:

```text
Customer Gateway ENI
```

---

# 9. Connect to Customer Gateway EC2

## Start SSM Session

```bash
aws ssm start-session \
  --target <CUSTOMER-GATEWAY-INSTANCE-ID> \
  --region eu-west-3
```

---

## Validate Instance Metadata

```bash
hostname

curl -s http://169.254.169.254/latest/meta-data/public-ipv4

curl -s http://169.254.169.254/latest/meta-data/local-ipv4
```

Expected:

```text
Public IP = Customer Gateway Elastic IP
Private IP = 172.16.0.100
```

---

# 10. Validate IPSec Configuration

## Check IPSec Service

```bash
sudo systemctl status ipsec --no-pager
```

---

## Validate Tunnel Status

```bash
sudo ipsec status
```

Expected:

```text
2 tunnels established
```

---

## Detailed IPSec Status

```bash
sudo ipsec auto --status
```

---

## Validate IPSec Traffic Counters

```bash
sudo ipsec trafficstatus
```

Expected:

- Increasing encrypted packet counters
- Active ESP SAs

---

# 11. Validate Cloud → Cloud Connectivity

## VPC-A → VPC-B

Connect:

```bash
aws ssm start-session \
  --target <VPC-A-INSTANCE-ID> \
  --region eu-west-3
```

Ping:

```bash
ping <VPC-B-PRIVATE-IP> -c 4
```

Expected:

```text
Success
```

---

## VPC-A → VPC-C

```bash
ping <VPC-C-PRIVATE-IP> -c 4
```

Expected:

```text
Success
```

---

# 12. Validate Cloud → On-Prem Connectivity

## From VPC-A

```bash
ping 172.16.1.100 -c 4
```

HTTP test:

```bash
curl http://172.16.1.100
```

Expected:

```text
Hello from On-Premises App Server
```

---

## From VPC-B

```bash
ping 172.16.1.100 -c 4

curl http://172.16.1.100
```

---

## From VPC-C

```bash
ping 172.16.1.100 -c 4

curl http://172.16.1.100
```

---

# 13. Validate DNS Resolution

## Test DNS Server

```bash
dig @172.16.1.200 myapp.example.corp
```

Expected:

```text
172.16.1.100
```

---

## Validate Application via DNS

```bash
curl http://myapp.example.corp
```

Expected:

```text
Hello from On-Premises App Server
```

---

# 14. Validate VPN HA Failover

This validates high availability between the two IPSec tunnels.

## Check Active Tunnels

```bash
sudo ipsec status
```

Expected:

```text
Tunnel 1 = UP
Tunnel 2 = UP
```

---

## Bring Down Tunnel 1

Example:

```bash
sudo ipsec down aws-tunnel-1
```

---

## Re-Test Connectivity

From cloud EC2:

```bash
ping 172.16.1.100 -c 4

curl http://172.16.1.100
```

Expected:

```text
Traffic still operational
```

Tunnel 2 should continue forwarding traffic.

---

## Restore Tunnel 1

```bash
sudo ipsec up aws-tunnel-1
```

---

# 15. Validate Network Path

## Trace Route

```bash
traceroute 172.16.1.100
```

Expected:

- Transit Gateway hop
- VPN path

---

# 16. Packet Capture Validation

## Capture IPSec Traffic

On Customer Gateway:

```bash
sudo tcpdump -i any esp
```

Generate traffic:

```bash
curl http://172.16.1.100
```

Expected:

```text
ESP encrypted packets visible
```

---

# 17. Validate Security Groups

Verify allowed traffic:

| Protocol | Port |
|---|---|
| ICMP | ALL |
| HTTP | 80 |
| DNS | 53 |
| IPSec | UDP/500 |
| NAT-T | UDP/4500 |
| ESP | Protocol 50 |

---

# 18. Troubleshooting

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

## Blackhole TGW Route

Cause:

```text
VPN tunnel unavailable
```

Verify:

```bash
aws ec2 describe-vpn-connections \
  --region eu-west-3 \
  --query 'VpnConnections[*].VgwTelemetry[*].[OutsideIpAddress,Status]' \
  --output table
```

---

## Cannot Reach On-Prem

Verify:

- VPN tunnels UP
- TGW routes active
- Route tables configured
- Security groups allow traffic
- IPSec service healthy

---

# 19. Successful Validation Criteria

The environment is fully operational when:

```text
✓ Both VPN tunnels are UP
✓ Transit Gateway routes are active
✓ Cloud VPCs communicate through TGW
✓ Cloud EC2 can reach 172.16.1.100
✓ HTTP returns:
  Hello from On-Premises App Server
✓ DNS resolution works:
  myapp.example.corp
✓ Tunnel failover works correctly
✓ ESP encrypted traffic visible
```

---

# 20. Recommended Advanced Testing

Future improvements for the modular project:

- Dynamic routing with BGP
- Route53 Resolver endpoints
- Centralized inspection VPC
- AWS Network Firewall
- Dual Customer Gateways
- Multi-region TGW peering
- CloudWatch VPN monitoring
- Terraform CI/CD pipelines
