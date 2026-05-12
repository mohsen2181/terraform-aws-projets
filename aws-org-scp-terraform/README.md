# 🏢 AWS Organizations & SCP Governance Platform with Terraform

> Enterprise-style AWS multi-account governance project using AWS Organizations, Organizational Units (OUs), Service Control Policies (SCPs), and Terraform.

---

# 📚 Project Overview

This project implements a real-world AWS multi-account governance architecture using:

- AWS Organizations
- Organizational Units (OUs)
- Service Control Policies (SCPs)
- Terraform Infrastructure as Code (IaC)
- Remote Terraform backend with Amazon S3
- Terraform state locking using S3 lockfile
- Modular Terraform design

The objective of this project is to:

- Understand AWS Organizations deeply
- Practice SCP inheritance and governance
- Build a reusable Terraform landing-zone foundation
- Prepare for AWS SAA-C03 certification
- Simulate enterprise AWS governance patterns

---

# 🧠 Core AWS Concepts Covered

| Topic | Covered |
|---|---|
| AWS Organizations | ✅ |
| Organizational Units (OUs) | ✅ |
| Multi-account governance | ✅ |
| SCP inheritance | ✅ |
| SCP explicit deny behavior | ✅ |
| Root user restrictions | ✅ |
| Region restriction SCPs | ✅ |
| Management account vs member accounts | ✅ |
| Terraform modules | ✅ |
| Remote Terraform backend | ✅ |
| Terraform state migration | ✅ |
| Terraform state locking | ✅ |
| Account vending basics | ✅ |
| AWS Organizations hierarchy | ✅ |
| SCP testing and validation | ✅ |

---

# 🏗️ Final Architecture

```text
Management Account
│
└── Organization Root
    ├── Security OU
    ├── Infrastructure OU
    ├── Sandbox OU
    │    └── sandbox-test-account
    └── Workloads OU
         ├── Dev OU
         ├── Test OU
         └── Prod OU
```

---

# 🔐 Governance Architecture

## Management Account

The management account:

- Owns the AWS Organization
- Creates OUs
- Creates member accounts
- Manages SCPs
- Is NOT affected by SCPs

---

## Organization Root

The organization root is the top-level hierarchy container.

It is NOT an AWS account.

It is:

- the parent of all OUs
- a valid SCP attachment target
- the top node of the organization tree

---

## Organizational Units (OUs)

Implemented OUs:

```text
Root
├── Security
├── Infrastructure
├── Sandbox
└── Workloads
    ├── Dev
    ├── Test
    └── Prod
```

Purpose of OUs:

- logical account grouping
- SCP inheritance boundaries
- environment segregation
- governance segmentation

---

# 🔐 Service Control Policies (SCPs)

## 1. BaselineSecurityControls SCP

This SCP contains:

- deny leaving organization
- deny root user actions
- deny disabling CloudTrail
- deny disabling GuardDuty
- deny disabling Security Hub
- deny disabling AWS Config

---

## 2. RestrictRegions SCP

This SCP:

- allows only approved AWS regions
- blocks operations in non-approved regions
- includes AWS global service exceptions

Allowed regions:

```text
eu-west-1
us-east-1
```

---

# 🧠 SCP Inheritance

Hierarchy:

```text
Root
 └── Sandbox OU
      └── sandbox-test-account
```

The member account inherits SCPs from:

- Root
- Parent OU
- Account-level SCPs

Effective SCPs are cumulative.

Any explicit deny overrides all IAM permissions.

---

# ❗ Important SCP Rules

## SCPs DO NOT grant permissions

SCPs only define:

```text
Maximum allowed permissions
```

IAM policies are still required.

---

## SCP explicit deny overrides everything

Even:

- AdministratorAccess
- IAM roles
- root user permissions

cannot bypass SCP denies.

---

## SCPs do NOT affect the management account

SCPs affect only:

- member accounts
- IAM users/roles inside member accounts
- member account root users

The management account is exempt.

---

# 🧪 SCP Validation Tests

## Test 1 — Deny Leaving Organization

```bash
aws organizations leave-organization
```

Expected:

```text
AccessDeniedException
```

---

## Test 2 — Region Restriction

Allowed region:

```bash
aws ec2 describe-instances --region eu-west-1
```

Blocked region:

```bash
aws ec2 describe-instances --region ap-southeast-1
```

Expected:

```text
explicit deny in a service control policy
```

---

# 🧱 Terraform Architecture

```text
aws-org-scp-terraform/
├── backend.tf
├── bootstrap-backend/
├── docs/
├── modules/
│   ├── account/
│   ├── organizational-unit/
│   ├── scp/
│   └── scp-attachment/
├── policies/
│   ├── baseline-security-controls.json
│   └── restrict-regions.json
├── main.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars
└── variables.tf
```

---

# 🌍 Remote Terraform Backend

This project uses:

```text
Amazon S3
```

for remote Terraform state.

Backend configuration:

```hcl
terraform {
  backend "s3" {
    bucket       = "aws-org-scp-terraform-terraform-state"
    key          = "aws-organizations/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

---

# 🔒 Terraform Locking

This project uses:

```text
S3 native lockfile
```

Terraform creates temporary `.tflock` objects during operations.

This prevents concurrent state modifications.

---

# 🔄 Terraform State Refactoring

This project used:

```bash
terraform state mv
```

to safely migrate resources into modules without recreating infrastructure.

---

# 🧪 Terraform Workflow

## Initialize

```bash
terraform init
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

---

# 🔍 Verify Organization

```bash
aws organizations describe-organization
```

---

# 🔍 Verify SCP Attachments

```bash
aws organizations list-policies-for-target \
  --target-id <OU_OR_ACCOUNT_ID> \
  --filter SERVICE_CONTROL_POLICY
```

---

# 🧠 AWS SAA-C03 Concepts Practiced

This project is strongly aligned with:

- AWS Organizations
- Governance at scale
- SCP behavior
- Multi-account strategy
- Security guardrails
- AWS region governance
- Root account security
- IAM vs SCP evaluation
- Landing zone concepts
- Terraform IaC practices

---

# 🚀 Future Enhancements

Possible next steps:

- IAM Identity Center (AWS SSO)
- CloudTrail organization trail
- Tag Policies
- Backup Policies
- Cost control SCPs
- Delegated administrators
- Security Hub centralization
- GuardDuty organization management
- Terraform CI/CD pipelines

---

# 🎯 Learning Outcomes

By completing this project, you gain practical experience with:

- AWS governance
- SCP inheritance
- Multi-account AWS design
- Enterprise Terraform practices
- Secure cloud architecture
- AWS certification preparation
- Terraform modularization
- Remote state management
- AWS security controls

---

# 📌 Final Notes

This project intentionally focuses on:

```text
AWS Organizations + SCP Governance
```

using:

```text
Terraform Infrastructure as Code
```

to simulate a realistic enterprise AWS landing-zone foundation.
