# AWS Multi-AZ High-Availability Web Application Infrastructure

An enterprise-grade, highly available, and cost-optimized two-tier web application infrastructure provisioned entirely with **Terraform** on **AWS**.

The stack deploys an **Application Load Balancer (ALB)** with an **ACM SSL/TLS Certificate** and **Route 53 DNS**, terminating TLS at the load balancer and routing decrypted traffic via an **ALB Target Group (HTTP Port 80)** to **Apache + PHP 8.x** web servers in private subnets, backed by an **Amazon RDS MySQL Multi-AZ** database instance with automatic failover.

> 💰 **Cost Optimization**: The costly NAT Gateway (~$32.40/month) is replaced with a **100% Free S3 Gateway VPC Endpoint**, enabling private EC2 instances to download Amazon Linux 2023 repository packages (`httpd`, `php`, `php-mysqli`, `mariadb105`) directly over the internal AWS network without exposing instances to the public internet.

---

## 🏗️ Architecture Overview

```text
                                  [ Internet User ]
                                          │
                                          │ 🔒 Encrypted HTTPS (Port 443)
                                          ▼
                            [ Route 53 Hosted Zone ]
                               (e.g., example.com)
                                          │
                    ┌─────────────────────┴─────────────────────┐
                    │     Application Load Balancer (ALB)       │
                    │   ┌─────────────────────────────────────┐ │
                    │   │   ACM SSL/TLS Certificate           │ │
                    │   │   [★ TLS / SSL TERMINATION POINT ★] │ │
                    │   │   • Decrypts HTTPS Traffic (Port 443)│ │
                    │   │   • Port 80 -> 443 HTTP 301 Redirect│ │
                    │   └──────────────────┬──────────────────┘ │
                    └──────────────────────┼────────────────────┘
                                           │
                                           │ 🔓 Plaintext HTTP (Port 80)
                                           ▼
                    ┌───────────────────────────────────────────┐
                    │             ALB Target Group              │
                    │     (Port 80 HTTP / Round Robin)          │
                    └──────────────────────┬────────────────────┘
                                           │
      ┌────────────────────────────────────┴────────────────────────────────────┐
      │                                                                         │
      ▼                                                                         ▼
┌─────────────────────────────────────────────┐   ┌─────────────────────────────────────────────┐
│ Availability Zone 1                         │   │ Availability Zone 2                         │
│                                             │   │                                             │
│ ┌─────────────────────────────────────────┐ │   │ ┌─────────────────────────────────────────┐ │
│ │ Public Subnet (10.10.0.0/24)            │ │   │ │ Public Subnet (10.10.1.0/24)            │ │
│ │ • ALB Node 1                            │ │   │ │ • ALB Node 2                            │ │
│ └─────────────────────────────────────────┘ │   │ └─────────────────────────────────────────┘ │
│                                             │   │                                             │
│ ┌─────────────────────────────────────────┐ │   │ ┌─────────────────────────────────────────┐ │
│ │ Private Web Subnet (10.10.13.0/24)      │ │   │ │ Private Web Subnet (10.10.14.0/24)      │ │
│ │ • Target: EC2 Web Server 1              │ │   │ │ • Target: EC2 Web Server 2              │ │
│ │   (Apache httpd Port 80 + PHP 8)        │ │   │ │   (Apache httpd Port 80 + PHP 8)        │ │
│ └───────────────────┬─────────────────────┘ │   │ └───────────────────┬─────────────────────┘ │
│                     │                       │   │                     │                       │
│                     │   ┌───────────────────┴───┴───────────────────┐ │                       │
│                     ├──►│       Free S3 Gateway VPC Endpoint        │◄┤                       │
│                     │   │   (Amazon Linux 2023 dnf/yum packages)    │ │                       │
│                     │   └───────────────────────────────────────────┘ │                       │
│                     │                                                 │                       │
│                     └───────────────────┐       ┌─────────────────────┘                       │
│                                         ▼   ▼   ▼   ▼                                         │
│ ┌─────────────────────────────────────────┐ │   │ ┌─────────────────────────────────────────┐ │
│ │ Private DB Subnet (10.10.11.0/24)       │ │   │ │ Private DB Subnet (10.10.12.0/24)       │ │
│ │ • RDS MySQL Primary (Port 3306 - Active)│ │───┼──► RDS MySQL Standby (Synchronous Sync)   │ │
│ └─────────────────────────────────────────┘ │   │ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘   └─────────────────────────────────────────────┘
```

### Key Components & Traffic Flow

| Component | Protocol & Port | Description |
| :--- | :--- | :--- |
| **Client to ALB** | `HTTPS : 443` (Encrypted) | Encrypted TLS connection with ACM SSL Certificate. |
| **ALB (TLS Termination)** | `TLS Offloading` | ALB decrypts the HTTPS payload at the edge and attaches `X-Forwarded-Proto: https`. |
| **ALB Target Group** | `HTTP : 80` (Plaintext) | Routes traffic across EC2 instances in private subnets with health checks. |
| **Target Group to EC2** | `HTTP : 80` (VPC Private) | Apache Web Servers execute PHP without SSL overhead. |
| **EC2 to RDS Multi-AZ** | `MySQL : 3306` (Private) | High-availability MySQL database with synchronous standby replica in AZ 2. |
| **S3 Gateway Endpoint** | `VPC Endpoint` (Free) | Direct private network routing for Amazon Linux 2023 package repository. |

---

## 📁 Repository Structure

```text
.
├── provider.tf                # AWS Provider & default tags configuration
├── variables.tf               # Input variables (CIDRs, DB credentials, domain)
├── vpc.tf                     # VPC, 6 Subnets, IGW, S3 Gateway Endpoint, Route Tables
├── security_groups.tf         # Layered Security Groups for ALB, EC2, and RDS
├── alb.tf                     # ALB, Target Group (Port 80), HTTPS 443 Listener, HTTP 301 Redirect
├── acm.tf                     # ACM SSL Certificate with Route 53 DNS validation
├── ec2.tf                     # EC2 instances in private subnets with IAM & SSM
├── user_data.sh.tpl           # Startup script installing Apache, PHP, and MySQL app
├── rds.tf                     # Multi-AZ Amazon RDS MySQL instance & Subnet Group
├── route53.tf                 # Route 53 Public Hosted Zone and Alias A records
├── outputs.tf                 # Outputs (ALB DNS, Website URL, RDS Endpoint)
├── terraform.tfvars.example   # Example variables configuration
├── .gitignore                 # Git ignore rules for state and sensitive data
└── README.md                  # Project documentation
```

---

## 🚀 Getting Started & Deployment

### 1. Prerequisites
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured (`aws configure`).
- [Terraform](https://www.terraform.io/downloads) (>= 1.5.0) installed.
- A registered domain name (e.g., `example.com`).

### 2. Configure Variables
Create your `terraform.tfvars` from the example:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Update `terraform.tfvars`:
```hcl
aws_region        = "us-east-1"
environment       = "production"
domain_name       = "example.com"
db_name           = "sampledb"
db_username       = "dbadmin"
db_password       = "YourStrongPassword123!"
instance_type     = "t3.micro"
db_instance_class = "db.t3.micro"
```

### 3. Deploy the Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

---

## 🌐 Route 53 & ACM Certificate Troubleshooting Guide

### Why `aws_acm_certificate_validation` can hang on redeploys:
When deploying or re-deploying Route 53 with Terraform, keep in mind how AWS manages Name Servers:

1. **New Hosted Zone = New Name Servers**:
   - Every time Terraform creates a new `resource "aws_route53_zone"`, AWS allocates **4 completely new Name Servers** (e.g., `ns-xxx.awsdns-xx.com`).
   - If your domain registrar (Route 53 Registered Domains, GoDaddy, Namecheap, etc.) is still pointing to older Name Servers, public DNS queries to the new CNAME validation record will return `Query refused` / `SERVFAIL`.
   - As a result, AWS Certificate Manager (ACM) cannot resolve the validation record and hangs in `Still creating...`.

2. **Fixing a Pending ACM Validation**:
   - Check the 4 Name Servers assigned to your newly created Hosted Zone (`terraform output route53_name_servers` or Route 53 Console).
   - Go to your Domain Registrar $\rightarrow$ **Edit Name Servers**, and paste those 4 new name servers.
   - Once saved, ACM will validate in 1–2 minutes.

3. **Production Best Practice (`data "aws_route53_zone"`)**:
   - To avoid updating registrar name servers on every `terraform destroy` and `terraform apply`, manage your Route 53 Hosted Zone outside the ephemeral application lifecycle.
   - Reference the existing zone in `route53.tf` and `acm.tf` using a data source:
     ```hcl
     data "aws_route53_zone" "primary" {
       name         = var.domain_name
       private_zone = false
     }
     ```
   - This ensures the Name Servers **never change**, and ACM certificate validation completes in **under 30 seconds** on every subsequent deployment.

---

## 🧪 Testing Amazon RDS Multi-AZ Database Failover

Amazon RDS Multi-AZ uses synchronous physical replication. When a failover occurs, AWS promotes the standby replica to primary and updates the DNS endpoint to point to the new master without requiring any application code changes.

### Step 1: Check Current Availability Zone (Before Failover)
Run the following AWS CLI command to see which AZ is currently active:
```bash
aws rds describe-db-instances \
  --db-instance-identifier mysql-database \
  --query "DBInstances[0].{Identifier:DBInstanceIdentifier, PrimaryAZ:AvailabilityZone, MultiAZ:MultiAZ, Status:DBInstanceStatus}" \
  --output table
```
*Example Output:*
```text
-------------------------------------------------------------------------
|                          DescribeDBInstances                          |
+----------------------+-----------+--------------------+---------------+
|      Identifier      |  MultiAZ  |     PrimaryAZ      |    Status     |
+----------------------+-----------+--------------------+---------------+
|  mysql-database      |  True     |  us-east-1a        |  available    |
+----------------------+-----------+--------------------+---------------+
```

---

### Step 2: (Optional) Monitor Website Availability in Real-Time
Open a separate PowerShell window to monitor continuous uptime during the test:
```powershell
while($true) {
    $time = Get-Date -Format "HH:mm:ss"
    try {
        $res = Invoke-WebRequest -Uri "https://example.com" -UseBasicParsing -TimeoutSec 3
        Write-Host "[$time] HTTP $($res.StatusCode) - Website is UP & Responsive" -ForegroundColor Green
    } catch {
        Write-Host "[$time] Database failing over... ($($_.Exception.Message))" -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 2
}
```

---

### Step 3: Trigger the Multi-AZ Failover
Execute the forced failover command:
```bash
aws rds reboot-db-instance --db-instance-identifier mysql-database --force-failover
```
*Output confirmation:*
```json
{
    "DBInstance": {
        "DBInstanceIdentifier": "mysql-database",
        "DBInstanceStatus": "rebooting",
        "AvailabilityZone": "us-east-1a",
        "MultiAZ": true
    }
}
```

---

### Step 4: Verify Failover and Automatic Promotion
Wait approximately 60–90 seconds and run:
```bash
aws rds describe-db-instances \
  --db-instance-identifier mysql-database \
  --query "DBInstances[0].{Identifier:DBInstanceIdentifier, NewPrimaryAZ:AvailabilityZone, Status:DBInstanceStatus}" \
  --output table
```

*Expected Result:*
- **Status**: Returns to `available`.
- **NewPrimaryAZ**: Swapped from `us-east-1a` to `us-east-1b`.
- **Data Integrity**: Refresh `https://example.com`—all existing employee records persist, and new data can be added immediately.

---

## 🔒 Security & Cost Architecture Highlights

1. **Zero NAT Gateway Cost**: Replaced NAT Gateway with a **Free S3 Gateway Endpoint**, saving **~\$32.40/month** while maintaining full package management capabilities for Amazon Linux 2023.
2. **Private Subnets**: Web EC2 instances and the RDS database have **no public IP addresses** and are not directly exposed to the internet.
3. **Security Group Isolation**:
   - **ALB SG**: Inbound allowed only on Ports 80 and 443 from `0.0.0.0/0`.
   - **Web EC2 SG**: Inbound allowed only on Port 80 strictly from the ALB Security Group ID.
   - **RDS SG**: Inbound allowed only on Port 3306 strictly from the Web EC2 Security Group ID.
4. **Database Credentials**: Injected securely into `/var/www/inc/dbinfo.inc` outside the Apache public document root (`/var/www/html/`).
5. **Encryption in Transit**: TLS 1.3/1.2 enforced by the ALB with automated certificate renewal via AWS Certificate Manager (ACM).

---

## 🧹 Teardown / Destroy
To clean up all AWS resources and avoid unnecessary charges:
```bash
terraform destroy -auto-approve
```
