# AWS EFS SA-C03 Lab with Terraform

## 📌 Project Overview

This project provisions a complete AWS networking and storage lab focused on **Amazon EFS** features commonly tested in the **AWS Solutions Architect Associate (SAA-C03)** certification.

The infrastructure is deployed using **Terraform** in the **eu-west-3 (Paris)** region.

The lab demonstrates:

- Custom VPC creation
- Multi-AZ subnet architecture
- EC2 deployment without SSH keys
- AWS Systems Manager Session Manager access
- Private EC2 instances with outbound Internet access through NAT Gateway
- Amazon EFS with:
  - Encryption at rest
  - Encryption in transit (TLS)
  - Mount targets
  - Access Points
  - Lifecycle Management
  - Automatic mounting

---

# 🏗 Architecture

```text
                         Internet
                             |
                     +---------------+
                     | Internet GW   |
                     +-------+-------+
                             |
                     +-------+-------+
                     |  NAT Gateway  |
                     | Public Subnet |
                     +-------+-------+
                             |
--------------------------------------------------------------
|                     Private Subnets                        |
|                                                            |
| +---------------+  +---------------+  +---------------+   |
| | EC2 Instance  |  | EC2 Instance  |  | EC2 Instance  |   |
| | SSM Access    |  | SSM Access    |  | SSM Access    |   |
| | EFS Mounted   |  | EFS Mounted   |  | EFS Mounted   |   |
| +-------+-------+  +-------+-------+  +-------+-------+   |
|         |                  |                  |           |
--------------------------------------------------------------
          |                  |                  |
+----------------------------------------------------------+
|                     Amazon EFS                           |
| Encryption + Access Point + Lifecycle Policies           |
|                                                          |
| Standard → IA → Archive → Standard (on access)           |
+----------------------------------------------------------+
```

VPC: 10.0.0.0/16
```

---

# 📂 Project Structure

```text
aws-efs-sa-c03-lab/
├── provider.tf
├── variables.tf
├── vpc.tf
├── subnet.tf
├── route_tables.tf
├── nat_gateway.tf
├── security.tf
├── iam.tf
├── endpoints.tf
├── efs.tf
├── ec2.tf
├── outputs.tf
├── user_data.sh.tpl
├── terraform.tfvars
└── README.md
```

---

# 🚀 Features Implemented

## ✅ Networking

- Custom VPC
- DNS support enabled
- 3 private subnets across Availability Zones
- Dedicated public subnet for NAT Gateway
- Internet Gateway
- NAT Gateway for outbound Internet access
- Route tables and subnet associations
- VPC Endpoints:
  - SSM
  - EC2Messages
  - SSMMessages

---

## ✅ EC2

- Amazon Linux 2023
- Private instances
- SSM managed instances
- No SSH keys required
- EFS mounted automatically during bootstrap
- Package installation supported through NAT Gateway

---

## ✅ Amazon EFS

### Implemented Features

| Feature | Status |
|---|---|
| Multi-AZ Mount Targets | ✅ |
| Encryption at Rest | ✅ |
| Encryption in Transit (TLS) | ✅ |
| EFS Access Point | ✅ |
| Lifecycle Management | ✅ |
| Automatic Mounting | ✅ |
| Shared Storage Across EC2s | ✅ |

---

# 📦 Prerequisites

## Install Terraform

```bash
terraform version
```

Recommended:

```text
Terraform >= 1.5
```

---

## Install AWS CLI

```bash
aws --version
```

---

## Configure AWS Credentials

```bash
aws configure
```

---

# 🛠 Initialize Project

```bash
terraform init
```

---

# 📋 Validate Configuration

```bash
terraform validate
```

---

# 🔍 Preview Infrastructure

```bash
terraform plan
```

---

# 🚀 Deploy Infrastructure

```bash
terraform apply -auto-approve
```

---

# 📤 Useful Outputs

Retrieve outputs:

```bash
terraform output
```

Example outputs:

- VPC ID
- Private subnet IDs
- NAT Gateway ID
- EFS ID
- EFS DNS name
- EC2 instance IDs
- SSM connection commands

---

# 🔐 Connect to EC2 via SSM

No SSH or key pair required.

```bash
aws ssm start-session \
--target <INSTANCE_ID> \
--region eu-west-3
```

---

# 🧪 Validate EFS Mount

Inside EC2:

```bash
mount | grep efs
```

Expected:

```text
127.0.0.1:/ on /mnt/efs type nfs4
```

This is expected when TLS is enabled using `amazon-efs-utils`.

---

# 🧪 Test Shared Storage

## On EC2-1

```bash
echo "hello from ec2-1" | sudo tee /mnt/efs/test.txt
```

## On EC2-2

```bash
cat /mnt/efs/test.txt
```

Expected:

```text
hello from ec2-1
```

---

# 🔒 Encryption Details

## Encryption at Rest

```hcl
encrypted = true
```

## Encryption in Transit

```bash
mount -t efs -o tls
```

Handled by:

- amazon-efs-utils
- stunnel

---

# ♻️ EFS Lifecycle Management

To optimize storage costs and demonstrate EFS storage classes, this lab enables automatic lifecycle transitions.

Configured in Terraform:

```hcl
# Move files to Infrequent Access
lifecycle_policy {
  transition_to_ia = "AFTER_30_DAYS"
}

# Move files from IA to Archive
lifecycle_policy {
  transition_to_archive = "AFTER_90_DAYS"
}

# Return files to Standard when accessed
lifecycle_policy {
  transition_to_primary_storage_class = "AFTER_1_ACCESS"
}
```

Lifecycle flow:

```text
Standard
   │
   └── 30 days no access
           ↓
Infrequent Access (IA)
           │
           └── 90 days no access
                   ↓
Archive
           │
           └── First file access
                   ↓
Standard
```

### Implemented Policies

| Policy | Purpose |
|---|---|
| `transition_to_ia` | Move inactive files to lower-cost IA |
| `transition_to_archive` | Archive cold data |
| `transition_to_primary_storage_class` | Restore active files automatically |

This demonstrates cost optimization concepts commonly covered in AWS SAA-C03.

# 📘 SA-C03 Concepts Covered

| Domain | Concepts |
|---|---|
| Storage | Amazon EFS, Lifecycle Management, IA, Archive |
| Security | Encryption |
| Networking | Private Subnets, NAT Gateway |
| Compute | EC2 |
| Identity | IAM Roles |
| Operations | Systems Manager |
| High Availability | Multi-AZ |

---

# 🧹 Destroy Infrastructure

```bash
terraform destroy -auto-approve
```

---

# 📚 References

- Amazon EFS
- AWS Systems Manager
- VPC Endpoints
- NAT Gateway
- Terraform AWS Provider

---