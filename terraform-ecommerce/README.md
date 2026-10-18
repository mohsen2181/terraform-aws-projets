# Production-Grade AWS eCommerce Microservices Platform with Enterprise FinOps

An enterprise-ready, highly available, secure eCommerce microservices web application deployed on **Amazon Web Services (AWS)** using **Terraform (Infrastructure as Code)**, **GitHub Actions (Zero-Secret OIDC GitOps)**, and an **Enterprise FinOps (Financial Engineering)** cost-optimization framework.

---

## 1. Architecture Overview

```
                                  [ Users / Browsers ]
                                            │
                                            ▼
                      ┌───────────────────────────────────────────┐
                      │    Route 53 Hosted Zone (Public DNS)      │
                      │          mycloudhomelab.click             │
                      │   - A Record: mycloudhomelab.click        │
                      │   - A Record: www.mycloudhomelab.click    │
                      │   - A Record: ecommerce.mycloud...        │
                      └─────────────────────┬─────────────────────┘
                                            │
                                            ▼
                      ┌───────────────────────────────────────────┐
                      │    CloudFront CDN (Global Distribution)   │
                      │  - ACM TLS Cert (mycloudhomelab.click)    │
                      │  - Default Cache Behavior: S3 Origin      │
                      │  - Custom SPA Error Caching (403/404->200)│
                      └─────────────────────┬─────────────────────┘
                                            │ Origin Access Control (OAC)
                                            ▼
                                ┌───────────────────────┐
                                │   S3 Static Bucket    │
                                │   (React Build SPA)   │
                                └───────────────────────┘

       [ React Client in Browser ] ─────────────────────────┐
                   │                                         │
                   ▼ (HTTPS API Calls)                       ▼ (User Auth)
     ┌───────────────────────────┐              ┌─────────────────────────┐
     │   HTTP API Gateway (v2)   │              │     Amazon Cognito      │
     │  - Native CORS            │              │  - User Pool            │
     │  - JWT Authorizer ────────┼──────────────┤  - App Client           │
     └─────────────┬─────────────┘              └─────────────────────────┘
                   │ VPC Link
                   ▼
  ═════════════════╪════════════════════════════════════════════════════════════════
  AWS VPC (10.10.0.0/16) - us-east-1 (Zero-Internet-Egress Private Cloud)
  ────────────────────────────────────────────────────────────────────────────────
  [ Public Subnets: 10.10.1.0/24 (us-east-1a) | 10.10.2.0/24 (us-east-1b) ]
    • Internet Gateway (IGW) - For VPC Link public routing
    • Zero NAT Gateway (Replaced by PrivateLink VPC Endpoints)
  ────────────────────────────────────────────────────────────────────────────────
  [ Private App Subnets: 10.10.11.0/24 (us-east-1a) | 10.10.12.0/24 (us-east-1b) ]
    │
    ▼
    ┌────────────────────────────────────────────────────────┐
    │          Internal Application Load Balancer            │
    │  - Port 80 Listener                                    │
    │  - Path Routing: /products*, /cart*, /users*, /orders* │
    └───────────┬──────────────┬──────────────┬──────────────┘
                │              │              │              │
      :8001     ▼    :8002     ▼    :8003     ▼    :8004     ▼
        ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
        │   Product    │ │     Cart     │ │     User     │ │    Order     │
        │   Service    │ │   Service    │ │   Service    │ │   Service    │
        │ (ECS Fargate)│ │ (ECS Fargate)│ │ (ECS Fargate)│ │ (ECS Fargate)│
        │  [FARGATE_   │ │  [FARGATE_   │ │  [FARGATE_   │ │  [FARGATE_   │
        │    SPOT]     │ │    SPOT]     │ │    SPOT]     │ │    SPOT]     │
        └──────┬───────┘ └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
               │                │                │                │
               ▼                ▼                ▼                ▼
        ┌──────────────┐ ┌──────────────┐ ┌─────────────┐  ┌──────────────┐
        │   DynamoDB   │ │   DynamoDB   │ │ RDS Postgres│  │  SNS Topic   │
        │  'products'  │ │    'cart'    │ │  (Port 5432)│  │ 'order-evts' │
        └──────────────┘ └──────────────┘ └─────────────┘  └──────┬───────┘
                                                                  │
                                                           ┌──────▼───────┐
                                                           │  SQS Queue   │
                                                           │ 'order-ship' │
                                                           └──────┬───────┘
                                                                  │ Event Source Mapping (Batch: 5)
                                                                  ▼
                                                       ┌─────────────────────┐
                                                       │ AWS Lambda (Py 3.11)│
                                                       │ 'order-processor'   │
                                                       │ - Updates status to │
                                                       │   'Shipped' in RDS  │
                                                       │ - Active X-Ray Trace│
                                                       └──────────┬──────────┘
                                                                  │ Port 5432
                                                                  ▼
                                                           [ RDS Postgres ]
  ────────────────────────────────────────────────────────────────────────────────
  [ VPC Endpoints Layer (Zero-Egress Private Communication - 8 Endpoints) ]
    • S3 Gateway Endpoint (Route Table: Free) -> ECR Image Layer Blobs & S3 Assets
    • DynamoDB Gateway Endpoint (Route Table: Free) -> Products & Cart Tables
    • ECR API Interface Endpoint (PrivateLink ENI) -> ECR Auth & Catalog
    • ECR DKR Interface Endpoint (PrivateLink ENI) -> Container Image Pulls
    • CloudWatch Logs Interface Endpoint (PrivateLink ENI) -> /ecs/ & /aws/lambda Log Streams
    • SSM Parameter Store Interface Endpoint (PrivateLink ENI) -> Secrets & Config
    • SNS Interface Endpoint (PrivateLink ENI) -> Order Event Publishing
    • AWS X-Ray Interface Endpoint (PrivateLink ENI) -> Zero-Egress Distributed Tracing
  ────────────────────────────────────────────────────────────────────────────────
  [ FinOps Governance & Cost Optimization ]
    • AWS Budgets: $25.00/mo spending limit with 80% & 100% email notifications
    • CloudWatch Billing Alarm: $20.00 threshold on EstimatedCharges
    • ECS Fargate Spot: 100% Spot capacity provider strategy (~70% compute savings)
    • S3 Lifecycle Configuration: Non-current versions expire after 14 days
    • Nightly Auto-Snooze: GitHub Actions cron scales ECS tasks to 0 overnight (~65% compute savings)
    • Infracost PR Bot: Automatic monthly cost delta breakdown on Pull Requests
  ════════════════════════════════════════════════════════════════════════════════
```

---

## 2. Technical Stack & Key Technologies

* **Cloud Provider**: Amazon Web Services (AWS) — Region `us-east-1`
* **Infrastructure as Code (IaC)**: Terraform `1.8.5` (13 modular packages)
* **Frontend Application**: React 18 SPA (React Router, Axios, Lucide Icons, Modern CSS)
* **Microservices**: Python 3.11 (FastAPI / Uvicorn containerized services)
* **Container Runtime**: AWS Elastic Container Service (ECS) running on **AWS Fargate Spot**
* **Databases**:
  * Amazon DynamoDB (`ecommerce-products` 100 items seeded; `ecommerce-cart`)
  * Amazon Aurora / RDS PostgreSQL 15 (`ecommerce-db`)
* **Asynchronous Messaging**: Amazon SNS (`ecommerce-order-events`) & Amazon SQS (`ecommerce-order-shipping-queue`)
* **Serverless Compute**: AWS Lambda (Python 3.11 order processor triggered by SQS)
* **Networking & Security**:
  * Custom 2-AZ VPC (`10.10.0.0/16`) with Zero NAT Gateways
  * 8 PrivateLink VPC Endpoints for secure, internal cloud traffic
  * AWS Cognito User Pool with Hosted UI and App Client
  * CloudFront CDN with TLS 1.3 & Origin Access Control (OAC)
  * Route 53 Public Hosted Zone with Apex and Subdomain Aliases (`mycloudhomelab.click`)
* **CI/CD & GitOps**: GitHub Actions with Zero-Secret AWS OIDC Authentication
* **Cost Engineering & FinOps**: AWS Budgets, CloudWatch Billing Alarms, Fargate Spot, S3 Lifecycle, Scheduled Snooze Workflows, and Infracost CLI.

---

## 3. Directory Layout

```
terraform-ecommerce/
├── backend/                             # Python FastAPI Microservices
│   ├── product-service/                 # Port 8001: DynamoDB Catalog API
│   ├── cart-service/                    # Port 8002: DynamoDB Cart API
│   ├── user-service/                    # Port 8003: RDS User Profile API
│   └── order-service/                   # Port 8004: RDS + SNS Event Publisher
├── data/                                # Sample Catalog & Media Assets
│   ├── products.json                    # 100 detailed eCommerce catalog items
│   ├── download-product-images.sh       # Downloads 100 sample images from Unsplash
│   ├── load-products.sh                 # Populates DynamoDB table from products.json
│   └── product-images/                  # Downloaded JPEG images (prod-001.jpg .. prod-100.jpg)
├── docs/                                # Project Documentation
│   └── GITHUB_ACTIONS_GUIDE.md          # Complete GitOps & FinOps CI/CD manual
├── environments/
│   └── dev/                             # Environment orchestration root
│       ├── main.tf                      # Instantiates all 13 modules
│       ├── outputs.tf                   # Endpoints & ARNs
│       ├── variables.tf                 # Global environment variables
│       └── versions.tf                  # AWS Provider & S3 backend lock config
├── frontend/
│   └── react-app/                       # React 18 eCommerce SPA
│       ├── public/                      # Static assets & index.html
│       └── src/                         # Components, Context, Pages & aws-config.js
├── lambda/
│   └── order-processor/                 # Python 3.11 Lambda triggered by SQS
│       ├── lambda_function.py           # Updates order status in RDS to 'Shipped'
│       └── requirements.txt
├── modules/                             # 13 Modular Reusable Terraform Packages
│   ├── 01-vpc/                          # VPC, Subnets, Route Tables, 8 VPC Endpoints
│   ├── 02-security/                     # Security Groups for ALB, ECS, RDS, Lambda
│   ├── 03-iam/                          # ECS Execution/Task Roles, Lambda Role
│   ├── 04-dynamodb/                     # Products & Cart DynamoDB tables
│   ├── 05-rds/                          # RDS PostgreSQL Subnet Group & Instance
│   ├── 06-sqs-sns/                      # Order Events SNS Topic & SQS Queue
│   ├── 07-alb/                          # Internal Application Load Balancer & Listeners
│   ├── 08-ecs/                          # ECS Cluster, Fargate Spot Providers, 4 Services
│   ├── 09-apigateway/                   # HTTP API Gateway v2, VPC Link, JWT Authorizer
│   ├── 10-frontend/                     # S3 Static Bucket, OAC, CloudFront, Lifecycle
│   ├── 11-order-processor/              # SQS Lambda Event Source Mapping
│   ├── 12-monitoring/                   # CloudWatch Dashboard, Alarms, X-Ray
│   └── 13-finops/                       # AWS Budgets ($25 limit) & Billing Alarm ($20)
├── scripts/                             # Deployment & Configuration Utilities
│   ├── build-and-push-images.sh         # Builds Docker images and pushes to ECR
│   ├── configure-frontend.sh            # Injects dynamic API & Cognito IDs into frontend
│   ├── deploy-all.sh                    # End-to-end master deployment script
│   ├── deploy-frontend.sh               # Builds and syncs React SPA to S3/CloudFront
│   └── seed-data.sh                     # Seeds DynamoDB and syncs product images
├── implementation_plan.md               # Master technical plan & verification test steps
└── README.md                            # Main project overview (this file)
```

---

## 4. FinOps: Cost Optimization Architecture

To ensure enterprise financial hygiene and prevent unexpected cloud bills, this project implements a **4-pillar FinOps framework**:

| # | FinOps Feature | Target Resource | Mechanism | Impact / Monthly Savings |
|---|---|---|---|---|
| **1** | **AWS Budgets & Alarm** | AWS Account Wide | Module `13-finops` | **$25.00/mo cap** with 80% & 100% email alerts |
| **2** | **Fargate Spot Compute** | 4 ECS Microservices | Module `08-ecs` | **~70% compute discount** using spare AWS capacity |
| **3** | **S3 Storage Lifecycle** | S3 Frontend Bucket | Module `10-frontend` | Purges non-current versions after 14 days |
| **4** | **Nightly Auto-Snooze** | ECS Task Desired Count | Actions Cron (`finops-snooze.yml`) | Scales to 0 overnight (**~65% compute savings**) |
| **5** | **Infracost PR Bot** | GitHub Pull Requests | Actions (`terraform-plan.yml`) | Shift-left cost delta comments on every PR |

### Estimated Cost Impact
* **Baseline Cost (24/7 On-Demand)**: ~$80.00+ / month.
* **FinOps Optimized Cost**: **~$15.00 – $20.00 / month** (**~75% overall reduction**).
* **Maximum Risk**: Capped at **$25.00 / month** with automated alerting.

---

## 5. Deployment Options

### Option A: Zero-Click GitOps via GitHub Actions (Recommended)
1. Commit and push your code to `main`.
2. The `.github/workflows/terraform-apply.yml` pipeline will automatically:
   * Authenticate to AWS via OIDC (zero stored secrets).
   * Run `terraform init`, `plan`, and `apply`.
   * Automatically seed the DynamoDB catalog with 100 products.
   * Download and synchronize all 100 product images to S3.
   * Dynamically configure `aws-config.js` and deploy the React SPA to CloudFront.
3. The `.github/workflows/microservices-ci.yml` pipeline will simultaneously build and push all 4 microservices Docker images to Amazon ECR.

### Option B: Local / VM Automated Master Script
```bash
# 1. Connect to your development environment:
cd terraform-ecommerce/scripts

# 2. Execute the master deployment script:
chmod +x deploy-all.sh
./deploy-all.sh
```

---

## 6. Verification & Test Steps

### 1. Storefront & Product Images
```bash
# Verify Storefront CDN
curl -sI https://mycloudhomelab.click

# Verify Product Image Asset Delivery (HTTP 200 OK)
curl -sI https://mycloudhomelab.click/images/products/prod-001.jpg
```

### 2. Microservices & API Gateway
```bash
# Query the live product catalog via HTTP API Gateway
curl -s https://upa76sz002.execute-api.us-east-1.amazonaws.com/products | head -c 200
```

### 3. FinOps Governance & Cost Checks
```bash
# Verify AWS Budget ($25.00 limit)
aws budgets describe-budgets --account-id 727742746869 \
  --query "Budgets[?BudgetName=='ecommerce-monthly-budget'].[BudgetName, BudgetLimit.Amount, TimeUnit]" \
  --output table

# Verify ECS Services on Fargate Spot
aws ecs describe-services --cluster ecommerce-cluster \
  --services ecommerce-product-service \
  --query "services[0].capacityProviderStrategy" --output json

# Test Auto-Snooze (Scale ECS down to 0)
for svc in ecommerce-product-service ecommerce-cart-service ecommerce-user-service ecommerce-order-service; do
  aws ecs update-service --cluster ecommerce-cluster --service "$svc" --desired-count 0 --region us-east-1 > /dev/null
done

# Test Auto-Wakeup (Restore ECS back to 1)
for svc in ecommerce-product-service ecommerce-cart-service ecommerce-user-service ecommerce-order-service; do
  aws ecs update-service --cluster ecommerce-cluster --service "$svc" --desired-count 1 --region us-east-1 > /dev/null
done
```

---

## 7. Verified Live Production Endpoints

| Resource | Live Endpoint / Value |
| :--- | :--- |
| **Storefront (CloudFront CDN)** | **[https://mycloudhomelab.click](https://mycloudhomelab.click)** |
| **CloudFront Distribution ID** | `E1AGV3AGUR46Y6` |
| **API Gateway (HTTP v2)** | `https://upa76sz002.execute-api.us-east-1.amazonaws.com` |
| **Catalog API** | `https://upa76sz002.execute-api.us-east-1.amazonaws.com/products` (100 products) |
| **Product Images** | `https://mycloudhomelab.click/images/products/prod-001.jpg` (HTTP 200 OK) |
| **AWS Monthly Budget** | `ecommerce-monthly-budget` ($25.00 limit, alerts at $20.00 & $25.00) |
| **CloudWatch Billing Alarm** | `ecommerce-billing-alarm-monthly` ($20.00 threshold) |
| **ECS Capacity Provider** | `FARGATE_SPOT` (100% weight across all 4 services) |
| **S3 Remote State Backend** | `s3://ecommerce-tfstate-727742746869/dev/terraform.tfstate` |
| **DynamoDB State Lock** | `ecommerce-tflocks` |
| **GitHub Actions IAM Role** | `arn:aws:iam::727742746869:role/github-actions-ecommerce-role` |
