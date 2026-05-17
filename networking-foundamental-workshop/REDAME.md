# 🌐 AWS Networking Fundamentals Workshop with Terraform

## 🏷️ Badges

![AWS](https://img.shields.io/badge/Cloud-AWS-orange?logo=amazon-aws)
![VPC](https://img.shields.io/badge/Networking-VPC-blue)
![EC2](https://img.shields.io/badge/Compute-EC2-yellow)
![NAT Gateway](https://img.shields.io/badge/Networking-NAT_Gateway-lightgrey)
![Internet Gateway](https://img.shields.io/badge/Networking-IGW-darkgreen)
![S3 Endpoint](https://img.shields.io/badge/VPC_Endpoint-S3_Gateway-green)
![Interface Endpoint](https://img.shields.io/badge/VPC_Endpoint-Interface-blueviolet)
![SSM](https://img.shields.io/badge/Management-SSM-red)
![IAM](https://img.shields.io/badge/Security-IAM-informational)

> Hands-on AWS networking project using Terraform to build a production-style VPC architecture with public/private subnets, NAT Gateway, Internet Gateway, EC2 instances, VPC endpoints, IAM roles, and Systems Manager connectivity.

---

# 📚 Project Overview

This project implements a foundational AWS networking architecture using:

- Amazon VPC
- Public and Private Subnets
- Multi-AZ networking design
- Internet Gateway (IGW)
- NAT Gateway (NAT GW)
- Route Tables
- Network ACLs (NACLs)
- Security Groups
- EC2 Instances
- VPC Gateway Endpoint (Amazon S3)
- VPC Interface Endpoints
- AWS Systems Manager (SSM)
- IAM Roles & Instance Profiles
- Terraform Infrastructure as Code (IaC)

The objective of this project is to:

- Understand AWS networking fundamentals deeply
- Practice public/private subnet design
- Understand VPC routing concepts
- Learn Internet Gateway vs NAT Gateway behavior
- Understand Gateway Endpoints vs Interface Endpoints
- Practice secure private subnet access using SSM
- Build reusable Terraform infrastructure
- Prepare for AWS SAA-C03 networking concepts
- Simulate enterprise-grade AWS network architecture

---

# 🧠 Core AWS Concepts Covered

| Topic | Covered |
|---|---|
| Amazon VPC | ✅ |
| CIDR planning | ✅ |
| Public subnet design | ✅ |
| Private subnet design | ✅ |
| Multi-AZ architecture | ✅ |
| Internet Gateway (IGW) | ✅ |
| NAT Gateway | ✅ |
| Route Tables | ✅ |
| Route propagation | ✅ |
| Security Groups | ✅ |
| Network ACLs (NACLs) | ✅ |
| IAM Roles for EC2 | ✅ |
| EC2 Instance Profiles | ✅ |
| AWS Systems Manager (SSM) | ✅ |
| Session Manager | ✅ |
| VPC Interface Endpoints | ✅ |
| VPC Gateway Endpoints | ✅ |
| Private AWS API connectivity | ✅ |
| Terraform IaC | ✅ |
| Terraform dependencies | ✅ |

---

# 🏗️ Final Architecture

```text
                           Internet
                               │
                               │
                     +----------------+
                     | Internet GW    |
                     +----------------+
                               │
                 ┌─────────────┴─────────────┐
                 │                           │
        Public Route Table          Private Route Table
                 │                           │
        ┌────────┘                           └────────┐
        │                                             │
  Public Subnet (AZ1)                         Private Subnet (AZ1)
        │                                             │
        │                                       Private EC2
        │                                             │
  Public Subnet (AZ2)                                 │
        │                                             │
   Public EC2                                  Interface Endpoints
        │                                    (KMS, SSM, EC2Messages,
        │                                      SSMMessages)
        │                                             │
        └────────────── NAT Gateway ─────────────────┘
                               │
                               ▼
                         AWS Services

                 S3 Gateway Endpoint
                     attached to
         Public + Private Route Tables
```

---

# 🌍 Network Architecture

## Amazon VPC

The project creates a dedicated:

```text
VPC A
```

with:

```text
10.0.0.0/16
```

Features enabled:

- DNS Support
- DNS Hostnames

Purpose:

- network isolation
- custom routing control
- subnet segmentation
- private AWS networking

---

# 🏢 Availability Zone Strategy

The architecture spans multiple Availability Zones (AZs) to simulate enterprise-grade network design.

Implemented:

```text
AZ1
├── Public Subnet
└── Private Subnet

AZ2
└── Public Subnet

AZ3
└── Private Subnet
```

Benefits:

- high availability
- fault isolation
- distributed workloads
- resilient networking

---

# 🌐 Public and Private Subnets

## Public Subnets

Public subnets:

- are associated with the public route table
- use an Internet Gateway
- can receive public IP addresses
- provide direct internet access

Typical workloads:

- Bastion hosts
- Internet-facing EC2
- Public applications

---

## Private Subnets

Private subnets:

- are associated with the private route table
- do NOT receive public IPs
- use NAT Gateway for outbound internet access
- use VPC endpoints for private AWS service connectivity

Typical workloads:

- backend services
- databases
- internal applications
- private compute workloads

---

# 🌍 Internet Gateway (IGW)

The project deploys:

```text
Internet Gateway
```

Purpose:

Provide internet access to:

```text
Public Subnets
```

Traffic flow:

```text
Public EC2
     ↓
Public Route Table
     ↓
Internet Gateway
     ↓
Internet
```

---

# 🔄 NAT Gateway

The project deploys:

```text
NAT Gateway
```

Purpose:

Allow private subnets to:

```text
initiate outbound internet access
```

without exposing workloads publicly.

Traffic flow:

```text
Private EC2
     ↓
Private Route Table
     ↓
NAT Gateway
     ↓
Internet Gateway
     ↓
AWS Public Services / Internet
```

Examples:

- package installation
- operating system updates
- AWS API calls without endpoints

---

# 🧭 Route Tables

## Public Route Table

Contains:

```text
0.0.0.0/0 → Internet Gateway
```

Associated with:

- public subnet (AZ1)
- public subnet (AZ2)

---

## Private Route Table

Contains:

```text
0.0.0.0/0 → NAT Gateway
```

Associated with:

- private subnet (AZ1)
- private subnet (AZ3)

---

# 🔐 Security Groups

A dedicated EC2 security group is created.

Rules:

### Inbound

```text
All ICMP IPv4
```

Purpose:

Enable:

```text
ping testing
```

### Outbound

```text
Allow all traffic
```

---

# 🧱 Network ACLs (NACLs)

A custom Network ACL is created and associated with all subnets.

Rules:

### Inbound

```text
Allow all traffic
```

### Outbound

```text
Allow all traffic
```

Purpose:

Simplify networking behavior for workshop testing.

---

# 🖥️ EC2 Architecture

The project deploys:

## Public EC2 Instance

Characteristics:

- Amazon Linux 2023
- Public subnet
- Public IP address
- SSM access enabled
- Static private IP

Purpose:

- internet-connected compute
- networking validation
- AWS CLI testing

---

## Private EC2 Instance

Characteristics:

- Amazon Linux 2023
- Private subnet
- No public IP
- SSM access enabled
- Static private IP

Purpose:

- private networking validation
- endpoint testing
- NAT Gateway testing

---

# 🔐 IAM Architecture

The project implements:

## EC2 IAM Role

Attached permissions:

```text
AmazonSSMManagedInstanceCore
AmazonS3FullAccess
```

Purpose:

- Systems Manager connectivity
- Session Manager access
- AWS CLI access from EC2
- S3 API access

---

## EC2 Instance Profile

The IAM role is attached to EC2 through:

```text
Instance Profile
```

Authentication flow:

```text
EC2
 ↓
IMDS (169.254.169.254)
 ↓
STS AssumeRole
 ↓
Temporary credentials
```

No access keys are required.

---

# 🔌 VPC Endpoints

## Gateway Endpoint — Amazon S3

The project deploys:

```text
S3 Gateway Endpoint
```

Attached to:

- Public Route Table
- Private Route Table

Purpose:

Provide:

```text
private connectivity to Amazon S3
```

without traversing:

```text
NAT Gateway
Internet Gateway
```

---

## Interface Endpoints

The project deploys interface endpoints for:

```text
KMS
SSM
SSM Messages
EC2 Messages
```

Purpose:

Provide:

```text
private AWS API connectivity
```

using:

```text
Elastic Network Interfaces (ENIs)
inside private subnets
```

Traffic stays:

```text
inside AWS private networking
```

without internet exposure.

---

# 🧱 Terraform Architecture

```text
networking-fundamental-workshop/
├── versions.tf
├── provider.tf
├── variables.tf
├── locals.tf
├── prereq-iam-s3.tf
├── vpc.tf
├── subnets.tf
├── nacl.tf
├── route-tables.tf
├── endpoints.tf
├── security-groups.tf
├── ec2.tf
├── outputs.tf
├── terraform.tfvars
├── README.md
└── testing-notes.md
```

---

# 🧪 Terraform Workflow

## Initialize

```bash
terraform init
```

## Format

```bash
terraform fmt -recursive
```

## Validate

```bash
terraform validate
```

## Plan

```bash
terraform plan
```

## Apply

```bash
terraform apply
```

## Destroy

```bash
terraform destroy
```

---

# 🧠 AWS SAA-C03 Concepts Practiced

This project is strongly aligned with:

- Amazon VPC
- Public vs private networking
- Internet Gateway vs NAT Gateway
- VPC routing
- Security Groups vs NACLs
- Multi-AZ design
- VPC Endpoints
- IAM roles for EC2
- AWS Systems Manager
- Private AWS service connectivity
- Terraform Infrastructure as Code
- Cloud networking architecture

---

# 🚀 Future Enhancements

Possible next steps:

- Application Load Balancer (ALB)
- Auto Scaling Group (ASG)
- Bastion host architecture
- Transit Gateway
- VPC Peering
- Route53 Private Hosted Zones
- VPC Flow Logs
- AWS Network Firewall
- PrivateLink architecture
- Multi-VPC design
- Terraform modules refactoring

---

# 🎯 Learning Outcomes

By completing this project, you gain practical experience with:

- AWS networking fundamentals
- VPC routing design
- NAT Gateway behavior
- Internet Gateway usage
- Private subnet architecture
- Gateway Endpoint vs Interface Endpoint
- Secure EC2 access with SSM
- IAM role authentication for EC2
- Enterprise Terraform practices
- AWS certification preparation

---

# 📌 Final Notes

This project intentionally focuses on:

```text
AWS Networking Fundamentals
```

using:

```text
Terraform Infrastructure as Code
```

to simulate a realistic AWS networking environment with public/private segmentation, private AWS service access, and secure infrastructure automation.

