# 🧪 AWS Hybrid DataSync Migration - Testing Notes

> Operational validation and testing commands for the AWS Hybrid NFS → DataSync → S3 migration project.

---

# ✅ Verify AWS Identity

```bash
aws sts get-caller-identity
```

---

# 🖥️ EC2 Discovery

## List EC2 Instances

```bash
aws ec2 describe-instances \
  --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name'].Value|[0],PrivateIpAddress]" \
  --output table \
  --region eu-west-3
```

---

# 🔎 Retrieve Instance IDs by Tags

## NFS Server

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=onprem-nfs-server" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text \
  --region eu-west-3
```

---

## App Server

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=onprem-app-server" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text \
  --region eu-west-3
```

---

## DataSync Agent

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=onprem-datasync-agent" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text \
  --region eu-west-3
```

---

# 🔐 AWS Systems Manager (SSM)

## Verify SSM Connectivity

```bash
aws ssm describe-instance-information \
  --region eu-west-3 \
  --output table
```

---

## Connect to EC2 Instance Using SSM

```bash
aws ssm start-session \
  --target i-0123456789abcdef0 \
  --region eu-west-3
```

---

## Connect to App Server Using Tags

```bash
aws ssm start-session \
  --target $(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=onprem-app-server" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text \
  --region eu-west-3) \
  --region eu-west-3
```

---

## Connect to NFS Server Using Tags

```bash
aws ssm start-session \
  --target $(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=onprem-nfs-server" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text \
  --region eu-west-3) \
  --region eu-west-3
```

---

# 📂 Validate NFS Server

Run inside the NFS Server:

```bash
sudo systemctl status nfs-server
sudo exportfs -v
sudo ss -tulpen | grep 2049
```

Expected:

```text
NFS service active
Port 2049 listening
Exported filesystem visible
```

---

# 📁 Generate Migration Test Files

Run inside the App Server:

```bash
sudo mkdir -p /mnt/data/test

for i in {1..10}; do
  echo "Migration test file $i" | sudo tee /mnt/data/test/file-$i.txt
done
```

---

# 🔄 AWS DataSync Operations

## List DataSync Tasks

```bash
aws datasync list-tasks --region eu-west-3
```

---

## Start DataSync Task

```bash
aws datasync start-task-execution \
  --task-arn arn:aws:datasync:eu-west-3:ACCOUNT_ID:task/TASK_ID \
  --region eu-west-3
```

---

## Monitor Migration

```bash
aws datasync describe-task-execution \
  --task-execution-arn arn:aws:datasync:eu-west-3:ACCOUNT_ID:task/TASK_ID/execution/EXECUTION_ID \
  --region eu-west-3
```

---

## Monitor Migration (Filtered Output)

```bash
aws datasync describe-task-execution \
  --task-execution-arn arn:aws:datasync:eu-west-3:ACCOUNT_ID:task/TASK_ID/execution/EXECUTION_ID \
  --region eu-west-3 \
  --query '{Status:Status,EstimatedFiles:EstimatedFilesToTransfer,FilesTransferred:FilesTransferred,BytesTransferred:BytesTransferred,ErrorCode:Result.ErrorCode,ErrorDetail:Result.ErrorDetail}'
```

---

# ☁️ Verify Migrated Files in S3

```bash
aws s3 ls s3://migration-lab-datasync-<suffix>/migration-output/ --recursive
```

Expected:

```text
migration-output/test/file-1.txt
migration-output/test/file-2.txt
...
```

---

# 🧹 Cleanup Notes

## Empty Versioned S3 Bucket

```bash
aws s3api delete-objects \
  --bucket <BUCKET_NAME> \
  --delete "$(aws s3api list-object-versions \
    --bucket <BUCKET_NAME> \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
```

---

## Destroy Infrastructure

```bash
terraform destroy
```

---

# 📚 Validation Goals

This testing workflow validates:

- AWS CLI access
- IAM permissions
- SSM connectivity
- NFS server functionality
- DataSync agent health
- DataSync migration execution
- S3 object migration
- Hybrid networking
- VPC peering
- VPC endpoint connectivity

---

# 🎯 Expected Final Outcome

```text
Application Server
        ↓ NFS
NFS Server
        ↓ NFS
DataSync Agent
        ↓ TLS
AWS DataSync Service
        ↓
Amazon S3 Bucket
```

Successful migration confirms the hybrid architecture is fully operational.
