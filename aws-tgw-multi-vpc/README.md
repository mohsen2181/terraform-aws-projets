# 🌐 AWS Transit Gateway Multi-VPC Lab with Terraform

![AWS](https://img.shields.io/badge/Cloud-AWS-orange?logo=amazon-aws)
![Transit Gateway](https://img.shields.io/badge/Networking-Transit_Gateway-blue)
![VPC](https://img.shields.io/badge/AWS-VPC-informational)
![SSM](https://img.shields.io/badge/Management-SSM-red)
![VPC Endpoint](https://img.shields.io/badge/Private_Access-VPC_Endpoints-green)
![EC2](https://img.shields.io/badge/Compute-EC2-yellow)

> Production-style AWS networking project using **Terraform** to build a **multi-VPC architecture** interconnected through **AWS Transit Gateway (TGW)** with **private-only EC2 connectivity**, **VPC Endpoints**, and **Systems Manager (SSM)** access — without NAT Gateway or bastion hosts.

---

# 📚 Project Overview

This project implements an **enterprise-style AWS network topology** composed of:

- **3 isolated Amazon VPCs**
- **AWS Transit Gateway (TGW)** for inter-VPC communication
- **Dedicated TGW attachment subnets**
- **Private EC2 instances**
- **VPC Interface Endpoints** for AWS private connectivity
- **S3 Gateway Endpoint**
- **AWS Systems Manager (SSM)** for secure private access
- **Terraform modular Infrastructure as Code (IaC)**

The architecture simulates a secure **hub-and-spoke network design**, commonly used in:

- Shared services environments
- Multi-application segmentation
- Platform engineering
- Enterprise cloud networking
- Secure east-west traffic patterns

---

# 🧠 AWS Concepts Practiced

| Topic | Covered |
|--------|----------|
| Amazon VPC | ✅ |
| CIDR Planning | ✅ |
| Multi-VPC Architecture | ✅ |
| Multi-AZ Design | ✅ |
| Public / Private Subnets | ✅ |
| AWS Transit Gateway | ✅ |
| TGW Route Propagation | ✅ |
| TGW VPC Attachments | ✅ |
| Route Tables | ✅ |
| Security Groups | ✅ |
| Private EC2 Connectivity | ✅ |
| AWS Systems Manager (SSM) | ✅ |
| Session Manager | ✅ |
| VPC Interface Endpoints | ✅ |
| VPC Gateway Endpoint (S3) | ✅ |
| IAM Roles & Instance Profiles | ✅ |
| Private AWS Service Connectivity | ✅ |
| Terraform Modules | ✅ |
| Infrastructure as Code | ✅ |

---

# 🏗️ Architecture

```text
                               ┌────────────────────┐
                               │  Transit Gateway   │
                               │       (TGW)        │
                               └─────────┬──────────┘
                                         │
                ┌────────────────────────┼────────────────────────┐
                │                        │                        │
        ┌───────▼────────┐      ┌───────▼────────┐      ┌───────▼────────┐
        │     VPC A      │      │     VPC B      │      │     VPC C      │
        │ 10.0.0.0/16    │      │ 10.1.0.0/16    │      │ 10.2.0.0/16    │
        ├────────────────┤      ├────────────────┤      ├────────────────┤
        │ Public Subnets │      │ Public Subnets │      │ Public Subnets │
        │ Private Subnets│      │ Private Subnets│      │ Private Subnets│
        │ TGW Subnets    │      │ TGW Subnets    │      │ TGW Subnets    │
        │ EC2 Test Host  │      │ EC2 Test Host  │      │ EC2 Test Host  │
        └───────┬────────┘      └───────┬────────┘      └───────┬────────┘
                │                       │                        │
        ┌───────▼────────┐     ┌───────▼────────┐      ┌───────▼────────┐
        │ VPC Endpoints  │     │ VPC Endpoints  │      │ VPC Endpoints  │
        │ SSM            │     │ SSM            │      │ SSM            │
        │ EC2Messages    │     │ EC2Messages    │      │ EC2Messages    │
        │ SSMMessages    │     │ SSMMessages    │      │ SSMMessages    │
        │ EC2 Endpoint   │     │ EC2 Endpoint   │      │ EC2 Endpoint   │
        │ S3 Gateway     │     │ S3 Gateway     │      │ S3 Gateway     │
        └────────────────┘     └────────────────┘      └────────────────┘
```

---

# 🌍 Network Design

## VPC Topology

The project deploys:

| VPC | CIDR |
|------|------|
| VPC A | `10.0.0.0/16` |
| VPC B | `10.1.0.0/16` |
| VPC C | `10.2.0.0/16` |

Each VPC contains:

- **2 Availability Zones**
- **Public Subnets**
- **Private Subnets**
- **Dedicated Transit Gateway Attachment Subnets**
- **Private EC2 test instance**
- **VPC Endpoints for AWS service access**

---

# 🔄 Transit Gateway Design

The architecture uses:

```text
AWS Transit Gateway (TGW)
```

to provide:

```text
Private VPC-to-VPC communication
```

without:

```text
VPC Peering
Public Internet
NAT Gateway
```

Traffic example:

```text
EC2 A (10.0.1.x)
        ↓
Private Route Table
        ↓
Transit Gateway
        ↓
VPC B Attachment
        ↓
EC2 B (10.1.1.x)
```

### Why Transit Gateway?

Benefits:

- centralized routing
- scalable architecture
- simplified multi-VPC connectivity
- enterprise-grade hub-and-spoke networking
- avoids VPC peering mesh complexity

---

# 🧩 Dedicated TGW Attachment Subnets

Each VPC contains:

```text
Dedicated TGW attachment subnets
```

Purpose:

AWS creates **Elastic Network Interfaces (ENIs)** inside these subnets for TGW attachments.

Benefits:

- routing isolation
- cleaner segmentation
- easier troubleshooting
- enterprise networking best practice

Example:

```text
VPC A
├── Public Subnets
├── Private Subnets
└── TGW Subnets
```

---

# 🔌 VPC Endpoints

To enable **private AWS API access**, the architecture deploys:

## Interface Endpoints

```text
SSM
SSMMessages
EC2Messages
EC2
```

Purpose:

Provide:

```text
Private Systems Manager connectivity
```

without:

```text
Internet Gateway
NAT Gateway
Public IP
```

Traffic remains:

```text
inside AWS private networking
```

---

## Gateway Endpoint

### Amazon S3

The project deploys:

```text
S3 Gateway Endpoint
```

Purpose:

Allow private instances to access:

```text
Amazon S3
```

without internet access.

Used for:

- package retrieval
- SSM dependencies
- secure private AWS access

---

# 🔐 Secure EC2 Access with SSM

Private EC2 instances are accessed using:

```bash
aws ssm start-session
```

instead of:

```text
SSH
Bastion Hosts
Public IPs
```

Authentication flow:

```text
EC2
 ↓
VPC Endpoint
 ↓
AWS Systems Manager
 ↓
Session Manager
```

Benefits:

- no inbound ports
- no SSH exposure
- no bastion hosts
- private-only administration

---

# 🧱 Terraform Project Structure

```text
aws-tgw-multi-vpc/
├── versions.tf
├── provider.tf
├── variables.tf
├── main.tf
├── endpoint.tf
├── ec2-test.tf
├── outputs.tf
├── terraform.tfvars
├── README.md
├── testing-notes.md
└── modules/
    └── vpc/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

# 🚀 Deployment

## Initialize Terraform

```bash
terraform init
```

## Format Code

```bash
terraform fmt -recursive
```

## Validate Configuration

```bash
terraform validate
```

## Review Changes

```bash
terraform plan
```

## Deploy Infrastructure

```bash
terraform apply
```

---

# 🧪 Validation & Testing

## Verify Transit Gateway Attachments

```bash
aws ec2 describe-transit-gateway-attachments \
  --filters "Name=resource-type,Values=vpc" \
  --region eu-west-3
```

Expected:

```text
available
```

---

## Verify SSM Managed Instances

```bash
aws ssm describe-instance-information \
  --region eu-west-3 \
  --output table
```

---

## Start Session

```bash
aws ssm start-session \
  --target <instance-id> \
  --region eu-west-3
```

---

## Validate Inter-VPC Connectivity

Example:

```bash
ping 10.1.1.x -c 4
ping 10.2.1.x -c 4
```

Expected:

```text
0% packet loss
```

---

# 🔍 Traffic Flow

## EC2 ↔ EC2 Communication

Uses:

```text
Transit Gateway
```

Flow:

```text
EC2
 ↓
Private Route Table
 ↓
Transit Gateway
 ↓
Remote VPC
 ↓
EC2
```

---

## EC2 ↔ AWS Services

Uses:

```text
VPC Endpoints
```

Flow:

```text
EC2
 ↓
VPC Endpoint
 ↓
AWS Service
```

Examples:

- Systems Manager
- Session Manager
- EC2 Messages
- S3

---

# 🎯 Skills Demonstrated

This project demonstrates hands-on experience with:

- AWS networking architecture
- Transit Gateway implementation
- Multi-VPC routing
- Private subnet communication
- Secure EC2 administration
- AWS Systems Manager
- VPC Endpoints
- IAM Roles & Instance Profiles

---

# 📌 Final Notes

This project focuses on building a:

```text
Secure Private Multi-VPC Architecture
```

using:

```text
Terraform + AWS Transit Gateway
```

to simulate a realistic **enterprise cloud networking topology** with secure inter-VPC communication and private AWS service access.