# 🔐 Secure WebApp with RDS, Lambda, API Gateway & Secrets Manager

> Terraform-based secure serverless architecture on AWS

------------------------------------------------------------------------

## 🏷️ Badges

![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4?logo=terraform)
![AWS](https://img.shields.io/badge/Cloud-AWS-orange?logo=amazon-aws)
![Lambda](https://img.shields.io/badge/Compute-Lambda-yellow)
![RDS](https://img.shields.io/badge/Database-RDS-blue) ![API
Gateway](https://img.shields.io/badge/API-Gateway-green) ![Secrets
Manager](https://img.shields.io/badge/Security-SecretsManager-red)

------------------------------------------------------------------------

## 🧱 Architecture

``` mermaid
flowchart TD
    A[Client] --> B[API Gateway]
    B --> C[Lambda Function]
    C --> D[RDS Database]
    C --> E[Secrets Manager]
```

------------------------------------------------------------------------

## 🚀 Key Features

-   Serverless API using API Gateway + Lambda
-   Secure database access via RDS
-   Secrets stored in AWS Secrets Manager
-   Private networking with VPC & endpoints
-   IAM roles with least privilege access
-   Fully automated with Terraform

------------------------------------------------------------------------

## 📁 Project Structure

    api.tf
    iam.tf
    init-lambda.tf
    init-trigger.tf
    lambda.tf
    main.tf
    networking.tf
    outputs.tf
    provider.tf
    rds.tf
    secrets.tf
    security.tf
    variables.tf
    vpc-endpoints.tf

------------------------------------------------------------------------

## 🚀 Deployment

``` bash
terraform init
terraform plan
terraform apply
```

------------------------------------------------------------------------

## 🛡️ Security Best Practices

-   Do not commit terraform.tfstate
-   Use Secrets Manager for credentials
-   Restrict network access via security groups
-   Use VPC endpoints to avoid public exposure

------------------------------------------------------------------------

## 💰 Cleanup

``` bash
terraform destroy
```
