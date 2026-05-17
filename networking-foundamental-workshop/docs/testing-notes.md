# Networking Fundamental Workshop — Validation & Test Notes

## Project Information

| Resource | Value |
|---|---|
| Region | `eu-west-3` |
| VPC ID | `vpc-0047a9c49165e17d9` |
| KMS Endpoint ID | `vpce-0b38e434fad833550` |
| S3 Endpoint ID | `vpce-0c617e87226a92f89` |
| S3 Bucket | `networking-day-eu-west-3-332782539408` |
| Public EC2 Instance ID | `i-088cd063653ce1dc8` |
| Public EC2 Private IP | `10.0.2.100` |
| Public EC2 Public IP | `15.237.109.201` |
| Private EC2 Instance ID | `i-022dbd98b3e16e34d` |
| Private EC2 Private IP | `10.0.1.100` |
| Public Subnet AZ1 | `subnet-03d90f84c3ebf7d71` |
| Public Subnet AZ2 | `subnet-0f5110afd44b248e2` |
| Private Subnet AZ1 | `subnet-0e381b0a3ff6d20c6` |
| Private Subnet AZ3 | `subnet-0db592d010ed72776` |

---

# 1. List EC2 Instances

```bash
aws ec2 describe-instances \
  --region eu-west-3 \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`]|[0].Value,State.Name,PrivateIpAddress,PublicIpAddress,Placement.AvailabilityZone]' \
  --output table
```

Expected:
- Public EC2 visible
- Private EC2 visible
- State = `running`

---

# 2. Verify IAM Instance Profile Attachment

```bash
aws ec2 describe-instances \
  --region eu-west-3 \
  --instance-ids i-022dbd98b3e16e34d i-088cd063653ce1dc8 \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,IamInstanceProfile.Arn,PrivateIpAddress,PublicIpAddress]' \
  --output table
```

Expected:

```text
arn:aws:iam::<account-id>:instance-profile/NetworkingWorkshopInstanceProfile
```

---

# 3. Verify SSM Connectivity

```bash
aws ssm describe-instance-information \
  --region eu-west-3 \
  --query 'InstanceInformationList[*].[InstanceId,PingStatus,PlatformName]' \
  --output table
```

Expected:

```text
PingStatus = Online
```

---

# 4. Connect to EC2 Using Session Manager

## Public EC2

```bash
aws ssm start-session \
  --region eu-west-3 \
  --target i-088cd063653ce1dc8
```

## Private EC2

```bash
aws ssm start-session \
  --region eu-west-3 \
  --target i-022dbd98b3e16e34d
```

---

# 5. Verify IAM Role from Inside EC2

Inside the EC2 instance:

```bash
aws sts get-caller-identity
```

Expected:
- Command succeeds
- ARN contains `NetworkingWorkshopEC2Role`

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

This confirms:
- AWS CLI is installed
- IAM role is attached
- Temporary credentials work
- AWS API connectivity works

---

# 6. Network Connectivity Paths

## Public EC2

```text
EC2
 ↓
Internet Gateway
 ↓
AWS API Endpoint
```

## Private EC2

```text
EC2
 ↓
Private Route Table
 ↓
NAT Gateway
 ↓
Internet Gateway
 ↓
AWS API Endpoint
```

VPC endpoint logic:

```text
If matching VPC endpoint exists
→ traffic uses VPC endpoint

Else
→ NAT Gateway
→ Internet Gateway
→ AWS public endpoint
```

---

# 7. Validate S3 Gateway Endpoint

From private EC2:

```bash
aws s3 ls
```

Expected:
- Succeeds
- Uses S3 Gateway Endpoint

Confirm endpoint:

```bash
aws ec2 describe-vpc-endpoints \
  --region eu-west-3 \
  --vpc-endpoint-ids vpce-0c617e87226a92f89 \
  --query 'VpcEndpoints[*].{EndpointId:VpcEndpointId,State:State,Type:VpcEndpointType}' \
  --output table
```

Expected:

```text
vpce-0c617e87226a92f89 | available | Gateway
```

---

# 8. Validate KMS Interface Endpoint

From EC2:

```bash
aws kms list-aliases --region eu-west-3
```

Expected:
- Command succeeds (requires IAM permissions)
- Uses KMS Interface Endpoint

---

# 9. VPC Endpoints Used

| Service | Endpoint Type |
|---|---|
| S3 | Gateway Endpoint |
| KMS | Interface Endpoint |
| SSM | Interface Endpoint |
| SSM Messages | Interface Endpoint |
| EC2 Messages | Interface Endpoint |

Behavior from private EC2:

```text
aws s3 ls
→ S3 Gateway Endpoint

aws kms list-aliases
→ KMS Interface Endpoint

aws sts get-caller-identity
→ NAT Gateway (no STS endpoint configured)
```

---

# 10. NAT Gateway Isolation Test

Objective:

Confirm that S3 and KMS still work from private EC2 after removing NAT Gateway routing.

Temporarily comment in Terraform:

```hcl
# resource "aws_route" "private_default_route" {
#   route_table_id         = aws_route_table.private.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.vpc_a_nat.id
# }
```

Apply:

```bash
terraform apply
```

From private EC2:

### S3 should still work

```bash
aws s3 ls
```

Expected:

✅ Success

### KMS should still work

```bash
aws kms list-aliases --region eu-west-3
```

Expected:

✅ Success

### STS should fail

```bash
aws sts get-caller-identity
```

Expected:

❌ Failure

This proves:

```text
S3 → Gateway Endpoint
KMS → Interface Endpoint
STS → NAT Gateway
```

---

# Conclusion

Validated:
- VPC routing
- Public/private subnet design
- NAT Gateway behavior
- S3 Gateway Endpoint
- KMS