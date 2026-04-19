# 🔐 AWS Secure CDN with Automated WAF Protection

> Cloud-native security pipeline using CloudFront, WAF, Lambda, Athena, and Terraform

---

## 🏷️ Badges
![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4?logo=terraform)
![AWS](https://img.shields.io/badge/Cloud-AWS-orange?logo=amazon-aws)
![CloudFront](https://img.shields.io/badge/CDN-CloudFront-blue)
![WAF](https://img.shields.io/badge/Security-WAF-red)
![Lambda](https://img.shields.io/badge/Compute-Lambda-yellow)
![Athena](https://img.shields.io/badge/Analytics-Athena-purple)
![Glue](https://img.shields.io/badge/ETL-Glue-blueviolet)

---

## 🧱 Architecture

```mermaid
flowchart TD
    A[User / Internet] --> B[CloudFront CDN]
    B -->|OAC| C[S3 Static Website]
    B --> D[WAF Protection]
    B --> E[CloudFront Logs]
    E --> F[S3 Log Bucket]
    F --> G[Lambda Auto Block]
    G --> H[WAF IP Set]
    F --> I[Glue Catalog]
    I --> J[Athena Queries]
```

---

## 🚀 Key Features

- Secure S3 origin using CloudFront OAC
- AWS WAF with managed + custom rules
- Automated IP blocking via Lambda
- Log analytics using Glue + Athena
- Fully automated with Terraform

---

## 🎯 Use Case

Simulates a real-world DevSecOps pipeline:
- Detect malicious traffic
- Analyze logs
- Automatically block attackers

---

## 🧠 Skills Demonstrated

- Terraform (IaC)
- AWS Security (WAF, IAM, OAC)
- Event-driven architecture
- Log analytics (Athena, Glue)
- Automation (Lambda)

---

## 🚀 Deployment

```bash
terraform init
terraform apply
```

---

## 🧪 Testing

### XSS Test
```bash
curl -G --data-urlencode "q=<script>alert(1)</script>" https://<url>
```

### SQLi Test
```bash
curl -G --data-urlencode "id=1 OR 1=1" https://<url>
```

---

## 💰 Cleanup

```bash
terraform destroy
```
