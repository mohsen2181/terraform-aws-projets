# AWS Hybrid Cloud Connectivity with Transit Gateway & Site-to-Site VPN

![Terraform](https://img.shields.io/badge/Terraform-v1.0+-623CE4?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Networking-FF9900?logo=amazonaws)
![Transit Gateway](https://img.shields.io/badge/AWS-Transit_Gateway-orange)
![VPN](https://img.shields.io/badge/Site--to--Site-VPN-blue)
![Hybrid Cloud](https://img.shields.io/badge/Architecture-Hybrid_Cloud-success)
![IaC](https://img.shields.io/badge/IaC-Terraform-blueviolet)
![Linux](https://img.shields.io/badge/Linux-Amazon_Linux_2023-FCC624?logo=linux)
![License](https://img.shields.io/badge/License-MIT-green)

## Overview

This project extends the **AWS Transit Gateway multi-VPC lab** by introducing a **simulated on-premises environment** connected to AWS using a **Site-to-Site VPN** attached to an **AWS Transit Gateway (TGW)**.

The objective is to simulate a **real hybrid cloud architecture**, where workloads running in AWS private VPCs can securely communicate with applications hosted in an on-premises network.

This project demonstrates:

- Hybrid cloud networking
- AWS Transit Gateway VPN attachments
- Site-to-Site VPN over IPsec with Libreswan
- Simulated on-premises routing with IP forwarding
- Internal enterprise DNS
- Private connectivity between AWS and on-prem resources
- SSM Session Manager access (no SSH/bastion required)
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
           (IPsec / IKEv2)
                 │
                 ▼
┌──────────────────────────────────────────┐
│          ON-PREMISES VPC                 │
│           172.16.0.0/16                  │
│                                          │
│  Customer Gateway VM (Libreswan)         │
│  172.16.0.100  [Public subnet]           │
│               │                          │
│      ┌────────┴────────┐                 │
│      │                 │                 │
│ App Server         DNS Server            │
│ 172.16.1.100       172.16.1.200          │
│ [Private subnet]   [Private subnet]      │
└──────────────────────────────────────────┘
```

### Network Overview

#### AWS Cloud

Three isolated VPCs connected through a centralized Transit Gateway:

| VPC   | CIDR           |
|-------|----------------|
| VPC A | `10.0.0.0/16`  |
| VPC B | `10.1.0.0/16`  |
| VPC C | `10.2.0.0/16`  |

Each VPC has public, private, and dedicated TGW subnets across two Availability Zones. The Transit Gateway acts as the **central routing hub** for both inter-VPC traffic and VPN connectivity.

---

#### Hybrid Connectivity

AWS is connected to the simulated on-premises environment via an **AWS Site-to-Site VPN** attached directly to the Transit Gateway. Two IPsec tunnels are created for redundancy:

- **Tunnel 2** — active, carries all traffic (`10.0.0.0/8` rightsubnet)
- **Tunnel 1** — loaded as hot standby (`auto=add`), can be brought up manually if tunnel 2 fails

This asymmetric active/standby design is intentional: when both tunnels use the same `rightsubnet`, the TGW may return replies on whichever tunnel it prefers, causing asymmetric routing. Keeping one tunnel active ensures traffic is always symmetric.

Traffic flow:

```text
AWS VPC → TGW → VPN Attachment → IPsec Tunnel → Customer Gateway → On-Prem Network
```

---

#### On-Premises Environment

Simulated using a dedicated VPC (`172.16.0.0/16`):

| Component            | IP Address      | Subnet  | Purpose                            |
|----------------------|-----------------|---------|-----------------------------------|
| Customer Gateway VM  | `172.16.0.100`  | Public  | VPN router, IP forwarding, Libreswan |
| App Server           | `172.16.1.100`  | Private | Internal enterprise application   |
| DNS Server           | `172.16.1.200`  | Private | `example.corp` internal DNS       |

---

## Key Design Decisions

### Libreswan over OpenSwan

The project uses **Libreswan** (not OpenSwan). OpenSwan is unmaintained and unavailable on Amazon Linux 2023. Libreswan is its actively maintained successor and is the package installed via `dnf install libreswan`.

### Amazon Linux 2023 for all instances

All instances use **Amazon Linux 2023**. AL2023 ships with the SSM agent pre-installed, uses `dnf` as its package manager, and receives longer-term security support compared to AL2.

### `left=` vs `leftid=` in Libreswan config

The Customer Gateway instance uses a private IP (`172.16.0.100`) on its network interface. The EIP (`15.x.x.x`) is applied externally by AWS via NAT and does not exist on any local interface.

Therefore the IPsec config separates:
- `left=172.16.0.100` — the IP the kernel binds to locally
- `leftid=<EIP>` — the identity AWS authenticates in IKE

Using `left=%defaultroute` or `left=<EIP>` causes ESP packets to be silently dropped because the kernel cannot find a matching local interface.

### No VTI interfaces

VTI (Virtual Tunnel Interface) mode was evaluated but rejected for this Libreswan version (4.12). Two issues were found:
- `mark=` requires hex notation (`0x01/0xffffffff`), not integers
- With `vti-routing=yes`, Libreswan installs xfrm policies with marks but xfrm states without them, causing a mismatch that silently drops all data packets

Plain xfrm tunnel mode with `leftsubnet`/`rightsubnet` works reliably on this version.

### SSM access without SSH

All instances have IAM instance profiles with `AmazonSSMManagedInstanceCore`. The on-prem private instances (app server, DNS server) use **VPC Interface Endpoints** for SSM, ssmmessages, and ec2messages so SSM traffic never leaves the VPC.

---

## Terraform Resources

### Networking

- `aws_vpc`, `aws_subnet`, `aws_internet_gateway`, `aws_nat_gateway`
- `aws_route_table`, `aws_route_table_association`, `aws_route`
- `aws_ec2_transit_gateway`, `aws_ec2_transit_gateway_route_table`
- `aws_ec2_transit_gateway_vpc_attachment`
- `aws_ec2_transit_gateway_route_table_association`
- `aws_ec2_transit_gateway_route_table_propagation`
- `aws_ec2_transit_gateway_route`
- `aws_customer_gateway`, `aws_vpn_connection`

### Compute

- `aws_instance`, `aws_eip`, `aws_eip_association`

### Security

- `aws_security_group`
- `aws_iam_role`, `aws_iam_instance_profile`

### DNS

- `aws_vpc_dhcp_options`, `aws_vpc_dhcp_options_association`

### VPC Endpoints

- `aws_vpc_endpoint` (Interface: ssm, ssmmessages, ec2messages, ec2 — for all VPCs including on-prem)
- `aws_vpc_endpoint` (Gateway: s3 — for cloud VPCs)

---

## Prerequisites

- Terraform v1.0+
- AWS CLI configured with appropriate permissions
- Your public IP address (used for the `participant_ip_address` variable)

---

## Deployment

```bash
git clone <repo>
cd aws-tgw-multi-vpc-vpn-on-premise

terraform init

terraform apply \
  -var="participant_ip_address=$(curl -s ifconfig.me)/32"
```

Default region is `eu-west-3` (Paris). Override with `-var="aws_region=eu-west-1"` if needed.

---

## Connectivity Validation

### Connect to instances via SSM

```bash
# Cloud instance
aws ssm start-session \
  --target <cloud-instance-id> \
  --region eu-west-3

# On-prem Customer Gateway
aws ssm start-session \
  --target $(terraform output -raw onprem_customer_gateway_instance_id) \
  --region eu-west-3
```

### Verify VPN tunnel status (from CGW instance)

```bash
sudo ipsec status
```

Expected: both connections loaded, tunnel-2 in `STATE_V2_ESTABLISHED_CHILD_SA`.

### Verify VPN tunnel status from AWS

```bash
aws ec2 describe-vpn-connections \
  --filters "Name=tag:Name,Values=On-Premises-to-TGW-VPN" \
  --region eu-west-3 \
  --query 'VpnConnections[0].VgwTelemetry[*].[OutsideIpAddress,Status]' \
  --output table
```

Expected: both tunnels `UP`.

### Ping cloud instances from on-prem CGW

```bash
ping -c 4 10.0.1.x   # VPC A
ping -c 4 10.1.1.x   # VPC B
ping -c 4 10.2.1.x   # VPC C
```

### Ping on-prem from a cloud instance

```bash
ping -c 4 172.16.1.100   # On-prem app server
ping -c 4 172.16.1.200   # On-prem DNS server
```

### HTTP validation

```bash
curl http://172.16.1.100
```

Expected:

```text
Hello from On-Premises App Server
```

### DNS validation

```bash
dig myapp.example.corp @172.16.1.200
```

Expected: resolves to `172.16.1.100`.

### Verify TGW route to on-prem

```bash
aws ec2 search-transit-gateway-routes \
  --transit-gateway-route-table-id $(terraform output -raw transit_gateway_route_table_id) \
  --filters Name=route-search.exact-match,Values=172.16.0.0/16 \
  --region eu-west-3
```

Expected: `state: active`, `type: static`.

---

## Failover to Tunnel 1

If tunnel 2 goes down, bring up the standby tunnel from the CGW instance:

```bash
sudo ipsec auto --up aws-tunnel-1
```

To make tunnel 1 the permanent active tunnel, swap `auto=start` / `auto=add` in `/etc/ipsec.conf` and restart ipsec.

---

## Learning Outcomes

This project demonstrates practical knowledge of:

- Hybrid Cloud Networking with AWS Transit Gateway
- Site-to-Site VPN and IPsec/IKEv2 tunnel negotiation
- Libreswan configuration and troubleshooting
- Asymmetric routing diagnosis and resolution
- AWS EIP NAT behaviour and its effect on VPN local binding
- SSM Session Manager for keyless instance access
- VPC Interface Endpoints for private AWS service access
- Infrastructure as Code with Terraform modules
- Hybrid DNS architecture with BIND
- Multi-layer network debugging (xfrm states, tcpdump, ipsec status)
