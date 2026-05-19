# AWS Transit Gateway Multi-VPC Lab – Testing Notes

## Overview

This lab validates connectivity between **three VPCs** interconnected through an **AWS Transit Gateway (TGW)**.

### Architecture

- **3 VPCs**
  - VPC A → `10.0.0.0/16`
  - VPC B → `10.1.0.0/16`
  - VPC C → `10.2.0.0/16`

- **Transit Gateway**
  - Inter-VPC communication

- **VPC Endpoints**
  - Used for **SSM access**
  - No NAT Gateway required

- **Private EC2 Test Instances**
  - One instance per VPC private subnet
  - Used to validate TGW communication

---

# Terraform Outputs

## Test Instances

```hcl
test_instances = {
  "a" = {
    id         = "i-0a7b294d5a2bc41c8"
    private_ip = "10.0.1.166"
  }

  "b" = {
    id         = "i-0f00953dbfa98d9e4"
    private_ip = "10.1.1.238"
  }

  "c" = {
    id         = "i-04ca20a3ba9ed55c1"
    private_ip = "10.2.1.148"
  }
}
```

---

## Transit Gateway

```hcl
transit_gateway_id = "tgw-05ff89a25c6d4aa7f"

transit_gateway_route_table_id = "tgw-rtb-0a653e74997977f52"
```

---

## VPC Details

### VPC A

```text
Name: tgw-lab-vpc-a
CIDR: 10.0.0.0/16
VPC ID: vpc-0a34b3b8abb73df0a
```

Private Subnets:

```text
subnet-0f40075b02c4bc834
subnet-0a57635230433a3c9
```

Public Subnets:

```text
subnet-0c1666fc3bcddd5ec
subnet-0fcaae8d0066baae7
```

TGW Subnets:

```text
subnet-03b03c4353ad37b9d
subnet-034b484f2808afb5c
```

---

### VPC B

```text
Name: tgw-lab-vpc-b
CIDR: 10.1.0.0/16
VPC ID: vpc-0feced0a70c3c9171
```

Private Subnets:

```text
subnet-0de360c9d5c22b706
subnet-0052b44533a8802f7
```

---

### VPC C

```text
Name: tgw-lab-vpc-c
CIDR: 10.2.0.0/16
VPC ID: vpc-0c6f88bfc7c76629a
```

Private Subnets:

```text
subnet-0cd26323581ed5a0f
subnet-035a795bcee66b547
```

---

# Validation Steps

## 1. Verify Transit Gateway Attachments

```bash
aws ec2 describe-transit-gateway-attachments \
  --filters "Name=resource-type,Values=vpc" \
  --region eu-west-3
```

Expected:

```text
State = available
```

for all VPC attachments.

---

## 2. Verify TGW Route Table

```bash
aws ec2 search-transit-gateway-routes \
  --transit-gateway-route-table-id tgw-rtb-0a653e74997977f52 \
  --filters Name=state,Values=active \
  --region eu-west-3
```

Expected routes:

```text
10.0.0.0/16
10.1.0.0/16
10.2.0.0/16
```

---

## 3. List EC2 Instances

```bash
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`]|[0].Value,InstanceId,VpcId,PrivateIpAddress,State.Name]' \
  --region eu-west-3 \
  --output table
```

Expected:

```text
tgw-lab-vpc-a-test-instance → 10.0.1.166
tgw-lab-vpc-b-test-instance → 10.1.1.238
tgw-lab-vpc-c-test-instance → 10.2.1.148
```

---

## 4. Verify VPC Endpoints

```bash
aws ec2 describe-vpc-endpoints \
  --region eu-west-3 \
  --query 'VpcEndpoints[*].[VpcEndpointId,VpcId,ServiceName,State,PrivateDnsEnabled]' \
  --output table
```

Expected:

### Interface Endpoints

```text
ssm
ssmmessages
ec2messages
ec2
```

### Gateway Endpoint

```text
s3
```

Expected state:

```text
available
```

---

## 5. Verify SSM Managed Instances

```bash
aws ssm describe-instance-information \
  --region eu-west-3 \
  --output table
```

Expected:

All EC2 instances should appear.

---

## 6. Verify IAM Role Policy

```bash
aws iam list-attached-role-policies \
  --role-name tgw-lab-ssm-role \
  --output table
```

Expected policy:

```text
AmazonSSMManagedInstanceCore
```

---

## 7. Verify Endpoint Security Group

```bash
aws ec2 describe-security-groups \
  --region eu-west-3 \
  --filters "Name=group-name,Values=*vpce-sg*" \
  --query 'SecurityGroups[*].[GroupName,VpcId,IpPermissions]' \
  --output json
```

Expected inbound rule:

```text
TCP 443
```

Allowed CIDRs:

```text
10.0.0.0/16
10.1.0.0/16
10.2.0.0/16
```

---

# Connectivity Tests

## Connect Using SSM

### VPC A

```bash
aws ssm start-session \
  --target i-0a7b294d5a2bc41c8 \
  --region eu-west-3
```

### VPC B

```bash
aws ssm start-session \
  --target i-0f00953dbfa98d9e4 \
  --region eu-west-3
```

### VPC C

```bash
aws ssm start-session \
  --target i-04ca20a3ba9ed55c1 \
  --region eu-west-3
```

---

## Ping Tests

### From VPC A

```bash
ping 10.1.1.238 -c 4
ping 10.2.1.148 -c 4
```

### From VPC B

```bash
ping 10.0.1.166 -c 4
ping 10.2.1.148 -c 4
```

### From VPC C

```bash
ping 10.0.1.166 -c 4
ping 10.1.1.238 -c 4
```

Expected:

```text
0% packet loss
```

---

# Traffic Flow Explanation

## EC2 ↔ EC2 Communication

Traffic between EC2 instances in different VPCs uses the:

```text
Transit Gateway (TGW)
```

Example:

```text
EC2 A (10.0.1.166)
        ↓
Private Route Table
        ↓
Transit Gateway
        ↓
VPC B Attachment
        ↓
EC2 B (10.1.1.238)
```

---

## EC2 ↔ AWS Services

Traffic to AWS Systems Manager uses:

```text
VPC Endpoints
```

Used for:

```text
aws ssm start-session
```

Flow:

```text
EC2
 ↓
VPC Endpoint
 ↓
AWS Systems Manager
```

---

# Final Result

Validated successfully:

- Transit Gateway routing
- TGW attachments
- Route propagation
- Private subnet communication
- VPC endpoints
- SSM connectivity
- Inter-VPC ICMP communication
- Private-only architecture (no NAT Gateway)
