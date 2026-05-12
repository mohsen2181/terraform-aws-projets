# 🧪 AWS Organizations & SCP Testing Notes

> Hands-on validation notes for AWS Organizations, Organizational Units (OUs), Service Control Policies (SCPs), SCP inheritance, and Terraform-managed AWS governance.

---

# 🔍 Validate AWS Identity

```bash
aws sts get-caller-identity
```

Output:

```json
{
    "UserId": "AIDAU263CSKIBEHMRKDFL",
    "Account": "332782539408",
    "Arn": "arn:aws:iam::332782539408:user/terraform-user"
}
```

This confirms:

- authenticated IAM user
- running in the management account
- Terraform user has AWS Organizations access

---

# 🏢 Validate AWS Organization

## Describe Organization

```bash
aws organizations describe-organization
```

Validation:

- AWS Organization exists
- SCPs are enabled
- ALL feature set enabled
- management account identified correctly

---

# 🌳 Validate Organization Root

```bash
aws organizations list-roots
```

Validation:

- organization root exists
- SCPs enabled at root level

---

# 🏗️ Validate Organizational Units (OUs)

## Root-Level OUs

```bash
aws organizations list-organizational-units-for-parent \
  --parent-id r-xnzl
```

Validated root OUs:

```text
Root
├── Security
├── Infrastructure
├── Sandbox
└── Workloads
```

---

## Workloads Child OUs

```bash
aws organizations list-organizational-units-for-parent \
  --parent-id ou-xnzl-9zcmprfc
```

Validated hierarchy:

```text
Workloads
├── Dev
├── Test
└── Prod
```

---

# 🔐 Validate SCP Attachments

```bash
aws organizations list-policies-for-target \
  --target-id ou-xnzl-yy2mzosq \
  --filter SERVICE_CONTROL_POLICY
```

Validation:

- SCPs successfully attached to Sandbox OU
- FullAWSAccess inherited
- custom SCPs active

---

# 👤 Validate Sandbox Member Account

```bash
aws organizations list-accounts-for-parent \
  --parent-id ou-xnzl-yy2mzosq
```

Validation:

- member account successfully created
- account attached to Sandbox OU
- SCP inheritance active

---

# 🔄 Assume Role Into Member Account

```bash
aws sts assume-role \
  --role-arn arn:aws:iam::606096000736:role/OrganizationAccountAccessRole \
  --role-session-name sandbox-test
```

Validate identity:

```bash
aws sts get-caller-identity
```

Expected:

```json
{
    "Account": "606096000736",
    "Arn": "arn:aws:sts::606096000736:assumed-role/OrganizationAccountAccessRole/sandbox-test"
}
```

Validation:

- authenticated inside member account
- SCPs now apply

---

# 🧪 SCP Validation Tests

# ✅ Test 1 — Deny Leaving Organization

```bash
aws organizations leave-organization
```

Expected Result:

```text
AccessDeniedException
```

---

# ✅ Test 2 — Region Restriction SCP

## Allowed Region

```bash
aws ec2 describe-instances --region eu-west-1
```

## Denied Region

```bash
aws ec2 describe-instances --region eu-west-2
```

Expected:

```text
explicit deny in a service control policy
```

Validation:

- RestrictRegions SCP works correctly
- non-approved regions blocked

---

# ✅ Test 3 — CloudTrail Protection

```bash
aws cloudtrail stop-logging \
  --name kms-demo-trail \
  --region eu-west-1
```

Expected:

```text
AccessDeniedException
explicit deny in a service control policy
```

Validation:

- CloudTrail protection SCP works
- logging cannot be disabled

---

# ✅ Test 4 — AWS Config Protection

```bash
aws configservice stop-configuration-recorder \
  --configuration-recorder-name default \
  --region eu-west-1
```

Expected:

```text
AccessDeniedException
explicit deny in a service control policy
```

Validation:

- AWS Config protection active
- recorder cannot be stopped

---

# ✅ Test 5 — GuardDuty Protection

```bash
aws guardduty list-detectors --region eu-west-2
```

Expected:

```text
AccessDeniedException
explicit deny in a service control policy
```

Validation:

- GuardDuty protection active
- detector operations restricted

---

# 🔐 Root User Restriction Notes

The SCP:

```text
DenyRootUserActions
```

targets:

```text
arn:aws:iam::*:root
```

inside member accounts.

The member account root user can still:

- authenticate
- access AWS console
- use MFA

BUT AWS API actions are denied.

Examples:

```text
open S3           → denied
create EC2        → denied
modify IAM        → denied
delete CloudTrail → denied
```

---

# 🧠 SCP Inheritance Understanding

Current hierarchy:

```text
Management Account (not affected by SCPs)
│
├── Security OU
├── Infrastructure OU
├── Sandbox OU
│    └── sandbox-test-account
│         ├── SCPs apply here
│         └── Root user restricted here
│
└── Workloads OU
```

Important:

- SCPs do NOT affect the management account
- SCPs DO affect member accounts
- SCPs are inherited through the OU hierarchy

---

# 🎯 Final Validation Summary

| Validation | Result |
|---|---|
| AWS Organization created | ✅ |
| SCPs enabled | ✅ |
| Organizational hierarchy created | ✅ |
| Sandbox member account created | ✅ |
| SCP inheritance validated | ✅ |
| Leave organization denied | ✅ |
| Region restriction validated | ✅ |
| CloudTrail protection validated | ✅ |
| AWS Config protection validated | ✅ |
| GuardDuty protection validated | ✅ |
| Root user restrictions understood | ✅ |
| SCP explicit deny behavior validated | ✅ |
