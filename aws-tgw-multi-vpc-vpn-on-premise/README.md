# AWS Hybrid Cloud Connectivity with Transit Gateway & Site-to-Site VPN

![Terraform](https://img.shields.io/badge/Terraform-v1.0+-623CE4?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Networking-FF9900?logo=amazonaws)
![Transit Gateway](https://img.shields.io/badge/AWS-Transit_Gateway-orange)
![VPN](https://img.shields.io/badge/Site--to--Site-VPN-blue)
![Hybrid Cloud](https://img.shields.io/badge/Architecture-Hybrid_Cloud-success)
![IaC](https://img.shields.io/badge/IaC-Terraform-blueviolet)
![Linux](https://img.shields.io/badge/Linux-Amazon_Linux_2-FCC624?logo=linux)
![License](https://img.shields.io/badge/License-MIT-green)

## Overview

This project extends the **AWS Transit Gateway multi-VPC lab** by introducing a **simulated on-premises environment** connected to AWS using a **Site-to-Site VPN** attached to an **AWS Transit Gateway (TGW)**.

The objective is to simulate a **real hybrid cloud architecture**, where workloads running in AWS private VPCs can securely communicate with applications hosted in an on-premises network.

This project demonstrates:

- Hybrid cloud networking
- AWS Transit Gateway VPN attachments
- Site-to-Site VPN over IPsec
- Simulated on-premises routing
- Internal enterprise DNS
- Private connectivity between AWS and on-prem resources
- Infrastructure as Code (IaC) with Terraform

---

## Architecture

```text
                    AWS CLOUD
┌──────────────────────────────────────────┐
│                                          │
│   VPC A      VPC B       VPC C           │
│ 10.0/16     10.1/16     10.2/16          │
│      \         |         /               │
│       \        |        /                │
│         Transit Gateway                  │
│                │                         │
└────────────────┼─────────────────────────┘
                 │
           Site-to-Site VPN
                 │
                 ▼
┌──────────────────────────────────────────┐
│             ON-PREMISES VPC             │
│                                          │
│  Customer Gateway VM                    │
│  172.16.0.100                           │
│  (VPN Router / OpenSWAN)                │
│               │                          │
│      ┌────────┴────────┐                │
│      │                 │                │
│ App Server         DNS Server           │
│ 172.16.1.100       172.16.1.200         │
│ Internal App       example.corp DNS     │
│                                          │
└──────────────────────────────────────────┘
```

### Network Overview

#### AWS Cloud

The AWS environment contains three isolated VPCs connected through a centralized:

```text
AWS Transit Gateway
```

| VPC | CIDR |
|------|------|
| VPC A | `10.0.0.0/16` |
| VPC B | `10.1.0.0/16` |
| VPC C | `10.2.0.0/16` |

The Transit Gateway acts as the **central routing hub**, enabling:

- Inter-VPC communication
- Connectivity to on-premises resources through VPN

---

#### Hybrid Connectivity

The AWS cloud is connected to the simulated datacenter through:

```text
AWS Site-to-Site VPN
```

The VPN is attached directly to the:

```text
Transit Gateway
```

using a:

```text
Transit Gateway VPN Attachment
```

Traffic flow:

```text
AWS VPC → TGW → VPN → Customer Gateway → On-Prem Network
```

---

#### On-Premises Environment

The on-premises network is simulated using a dedicated VPC:

```text
172.16.0.0/16
```

Components:

| Component | IP Address | Purpose |
|------------|------------|----------|
| Customer Gateway VM | `172.16.0.100` | VPN Router / OpenSWAN |
| App Server | `172.16.1.100` | Internal enterprise application |
| DNS Server | `172.16.1.200` | `example.corp` DNS |

---

## Project Goals

This lab simulates a real-world enterprise hybrid architecture:

```text
AWS Cloud ↔ Corporate Datacenter
```

Typical enterprise use cases:

- Legacy applications hosted on-premises
- Cloud migration strategies
- Secure private communication between AWS and datacenter systems
- Hybrid DNS resolution
- Enterprise networking and routing concepts

---

## On-Premises Components

### 1. Customer Gateway (VPN Router)

**Role:** Simulates a physical datacenter firewall/router.

**EC2 Instance**

```text
Private IP : 172.16.0.100
Public IP  : Elastic IP
Subnet     : Public subnet
```

Responsibilities:

- Terminates IPsec VPN tunnels
- Routes traffic between AWS and on-prem
- Runs **OpenSWAN**
- Performs packet forwarding

Equivalent real-world devices:

- Cisco ASA
- Fortigate
- Palo Alto
- Juniper SRX
- StrongSwan VPN Gateway

---

### 2. On-Premises App Server

**Role:** Simulates an internal enterprise application.

```text
Private IP : 172.16.1.100
Subnet     : Private subnet
```

Runs:

```text
Apache HTTP Server
```

Used to validate:

```text
AWS → On-Prem connectivity
```

Example test:

```bash
curl http://172.16.1.100
```

Response:

```text
Hello from On-Premises App Server
```

---

### 3. On-Premises DNS Server

**Role:** Simulates an enterprise internal DNS server.

```text
Private IP : 172.16.1.200
Subnet     : Private subnet
```

Configured zone:

```text
example.corp
```

Example internal resolution:

```text
myapp.example.corp
→ 172.16.1.100
```

This mirrors common hybrid cloud DNS architectures.

---

## Hybrid Connectivity Flow

Traffic path between AWS and on-prem:

```text
EC2 (AWS VPC)
        ↓
Private Route Table
        ↓
Transit Gateway
        ↓
VPN Attachment
        ↓
IPsec Tunnel
        ↓
Customer Gateway
        ↓
On-Prem App Server
```

---

## Technologies Used

### Cloud Networking

- AWS Transit Gateway
- AWS Site-to-Site VPN
- AWS Customer Gateway
- VPC Routing
- Route Tables
- Security Groups
- Elastic IP

### Infrastructure as Code

- Terraform

### Operating Systems

- Amazon Linux 2
- Amazon Linux 2023

### VPN

- OpenSWAN
- IPsec

### Application Services

- Apache HTTP Server
- BIND DNS

---

## Terraform Resources Implemented

### Networking

- `aws_customer_gateway`
- `aws_vpn_connection`
- `aws_ec2_transit_gateway_route`
- `aws_ec2_transit_gateway_route_table_association`
- `aws_route`
- `aws_nat_gateway`
- `aws_internet_gateway`

### Compute

- `aws_instance`
- `aws_eip`
- `aws_eip_association`

### Security

- `aws_security_group`

### DNS

- `aws_vpc_dhcp_options`
- `aws_vpc_dhcp_options_association`

---

## Connectivity Validation

### Verify VPN Status

```bash
aws ec2 describe-vpn-connections \
  --vpn-connection-ids <vpn-id> \
  --region eu-west-3 \
  --query 'VpnConnections[0].VgwTelemetry[*].[OutsideIpAddress,Status]' \
  --output table
```

Expected:

```text
UP
```

---

### Verify Transit Gateway Route

```bash
aws ec2 search-transit-gateway-routes \
  --transit-gateway-route-table-id <tgw-route-table-id> \
  --filters Name=route-search.exact-match,Values=172.16.0.0/16 \
  --region eu-west-3
```

Expected:

```text
State: active
Type : static
```

---

### Test Hybrid Connectivity

Connect to a cloud EC2 instance:

```bash
aws ssm start-session \
  --target <cloud-ec2-instance-id> \
  --region eu-west-3
```

Ping on-prem server:

```bash
ping 172.16.1.100 -c 4
```

HTTP validation:

```bash
curl http://172.16.1.100
```

Expected output:

```text
Hello from On-Premises App Server
```

---

## Learning Outcomes

This project demonstrates practical knowledge of:

- Hybrid Cloud Networking
- AWS Transit Gateway
- Site-to-Site VPN
- IPsec Tunnels
- OpenSWAN Configuration
- Enterprise Routing
- Private Connectivity
- Infrastructure as Code with Terraform
- Hybrid DNS Architecture
- Multi-network troubleshooting

---