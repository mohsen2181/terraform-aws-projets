# Master Implementation Plan: AWS eCommerce Microservices Infrastructure

This master design document consolidates the complete end-to-end architecture, modular Terraform structure, container automation scripts, frontend continuous deployment pipeline, and step-by-step CLI verification tests for deploying Chetan Agrawal's eCommerce microservices web application on AWS (`us-east-1`).

---

## 1. High-Level Architecture Diagram

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
     │  - Native CORS:           │              │  - User Pool            │
     │    https://mycloud...     │              │  - App Client           │
     │    http://localhost:3000  │              └────────────┬────────────┘
     │  - JWT Authorizer ────────┼───────────────────────────┘
     └─────────────┬─────────────┘
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
        └──────┬───────┘ └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
               │                │                │                │
               │                │                ▼                │
               │                │         ┌─────────────┐         │
               │                │         │ RDS Postgres│         │
               │                │         │  (Port 5432)│         │
               ▼                ▼         └─────────────┘         ▼
        ┌──────────────┐ ┌──────────────┐                  ┌──────────────┐
        │   DynamoDB   │ │   DynamoDB   │                  │  SNS Topic   │
        │  'products'  │ │    'cart'    │                  │ 'order-evts' │
        └──────────────┘ └──────────────┘                  └──────┬───────┘
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
  [ Observability & Monitoring Layer (CloudWatch & AWS X-Ray) ]
    • CloudWatch Executive Dashboard: 'ecommerce-dev-dashboard' (API GW, ECS, RDS, SQS, Lambda)
    • CloudWatch Metric Alarms: 5xx Spikes, High RDS CPU (>85%), Lambda Error Spikes
    • SNS Alerting: 'ecommerce-alerts-dev' topic
    • AWS X-Ray: Distributed Tracing & End-to-End Service Map across all microservices
  ────────────────────────────────────────────────────────────────────────────────
  [ Private DB Subnets: 10.10.21.0/24 (us-east-1a) | 10.10.22.0/24 (us-east-1b) ]
    • RDS Subnet Group (Isolated database network layer)
  ════════════════════════════════════════════════════════════════════════════════
```

---

## 2. Project Directory Layout

```text
terraform-ecommerce/
├── backend/                                   # Microservices & Serverless Lambda Code
│   ├── product-service/                       # FastAPI (Port 8001) + Dockerfile
│   ├── cart-service/                          # FastAPI (Port 8002) + Dockerfile
│   ├── user-service/                          # FastAPI (Port 8003) + Dockerfile
│   ├── order-service/                         # FastAPI (Port 8004) + Dockerfile
│   └── order-processor/                       # Python 3.11 Lambda (SQS Consumer, RDS updater, X-Ray)
├── data/                                      # Catalog seed data & loading scripts
│   ├── product-images/                        # 100 High-Res product jpg images
│   ├── products.json                          # 100 Product records with CloudFront image URLs
│   ├── update-product-image-urls.sh           # Rewrites image links to CloudFront/Domain URLs
│   ├── upload-images-to-s3.sh                 # Syncs 100 local images to S3
│   └── load-products.sh                       # Batch writes 100 items into DynamoDB table
├── frontend/
│   └── react-app/                             # React SPA Application (Pagination, Search, Category Chips)
│       ├── src/aws-config.js                  # Injected live endpoints (Cognito & API Gateway)
│       └── package.json                       # React scripts and dependencies
├── scripts/                                   # Automation Pipelines
│   ├── deploy-all.sh                          # Master One-Click End-to-End Orchestrator (12 Modules)
│   ├── build-and-push-images.sh               # Builds 4 microservice Docker images & pushes to ECR
│   ├── configure-frontend.sh                  # Injects Terraform outputs into aws-config.js
│   └── deploy-frontend.sh                     # npm build + S3 sync + CloudFront cache invalidation
├── environments/
│   └── dev/
│       ├── main.tf                            # Root module orchestration (01 to 12)
│       ├── variables.tf                       # Input variable declarations
│       ├── terraform.tfvars                   # Sensitive passwords and custom domain parameters
│       ├── outputs.tf                         # Exposed infrastructure endpoints & IDs
│       └── provider.tf                        # AWS Provider definition (us-east-1)
└── modules/
    ├── 01-vpc/                                # VPC (10.10.0.0/16), 6 subnets, IGW, SGs, 8 VPC Endpoints (+ X-Ray)
    ├── 02-database/                           # RDS PostgreSQL + 2 DynamoDB Tables
    ├── 03-auth/                               # Cognito User Pool & App Client
    ├── 04-security/                           # SSM Parameter Store
    ├── 05-notification/                       # SNS Topic + SQS Queue + Subscription
    ├── 06-alb/                                # Internal ALB + 4 Target Groups + Path Rules
    ├── 07-ecr/                                # 4 ECR Repositories for Docker images
    ├── 08-ecs/                                # ECS Cluster + Fargate Services + Target-Tracking & Scheduled Auto-Scaling
    ├── 09-apigateway/                         # HTTP API Gateway (v2) + VPC Link + JWT Authorizer + CORS
    ├── 10-frontend/                           # S3 Static Site + OAC + CloudFront + ACM Cert + Route 53
    ├── 11-order-processor/                    # SQS-triggered Python 3.11 Lambda + VPC ENI + Active X-Ray Tracing
    └── 12-monitoring/                         # CloudWatch Executive Dashboard + 3 Metric Alarms + SNS Alerting Topic
```

---

## 3. Detailed Phase-by-Phase Technical Breakdown

### Phase 1: Private Networking & VPC Endpoints (`01-vpc`)
- **VPC**: `10.10.0.0/16` in `us-east-1`.
- **Subnets**:
  - Public: `10.10.1.0/24` (AZ a), `10.10.2.0/24` (AZ b)
  - Private App: `10.10.11.0/24` (AZ a), `10.10.12.0/24` (AZ b)
  - Private DB: `10.10.21.0/24` (AZ a), `10.10.22.0/24` (AZ b)
- **Zero-Internet-Egress**: NAT Gateway and Elastic IP replaced with AWS PrivateLink VPC Endpoints.
- **VPC Endpoints (7 total)**:
  - Gateway (Free): `s3` (Route table) and `dynamodb` (Route table).
  - Interface (PrivateLink): `ecr.api`, `ecr.dkr`, `logs`, `ssm`, `sns` with private DNS enabled.
- **Security Groups**:
  - `alb-sg`: HTTP:80 ingress from VPC Link SG.
  - `ecs-tasks-sg`: Ingress ports `8000-8004` strictly from `alb-sg`.
  - `rds-sg`: Ingress port `5432` strictly from `ecs-tasks-sg`.
  - `vpc-endpoints-sg`: Ingress port `443` (HTTPS) from `ecs-tasks-sg`.

### Phase 2: Data Persistence, Authentication & Messaging
- **Module `02-database`**:
  - DynamoDB Tables: `ecommerce-products` (`product_id`), `ecommerce-cart` (`user_id`). PAY_PER_REQUEST billing.
  - RDS PostgreSQL: `db.t3.micro`, 20GB storage, engine `16.3`, multi-AZ disabled for dev, deployed in private DB subnets.
- **Module `03-auth`**:
  - Cognito User Pool (`ecommerce-user-pool`) with email sign-in, auto-verify emails, password complexity.
  - Cognito App Client (`ecommerce-app-client`) with USER_PASSWORD_AUTH and SRP flows.
- **Module `04-security`**:
  - SSM Parameter Store entries: `/ecommerce/dev/aws/region`, `/ecommerce/dev/db/host`, `/ecommerce/dev/db/password`, `/ecommerce/dev/sns/topic-arn`.
- **Module `05-notification`**:
  - SNS Topic: `ecommerce-order-events`.
  - SQS Queue: `ecommerce-order-shipping`.
  - SQS subscription attached to SNS with raw message delivery.

### Phase 3: Internal Routing & Container Registries
- **Module `06-alb`**:
  - Internal Application Load Balancer (`ecommerce-internal-alb`) in private app subnets.
  - 4 Target Groups (target type `ip`, health check `/health`):
    - `product-service-tg` (Port 8001)
    - `cart-service-tg` (Port 8002)
    - `user-service-tg` (Port 8003)
    - `order-service-tg` (Port 8004)
  - Path-based routing rules: `/products*`, `/cart*`, `/users*`, `/orders*`.
  - SSM Parameters storing internal ALB service URLs.
- **Module `07-ecr`**:
  - 4 Container Registries: `ecommerce/product-service`, `ecommerce/cart-service`, `ecommerce/user-service`, `ecommerce/order-service`.
  - Image vulnerability scanning enabled on push.

### Phase 4: Container Compute & Auto-Scaling (`08-ecs`)
- **ECS Cluster**: `ecommerce-cluster` with Container Insights enabled.
- **IAM Roles**:
  - Execution Role: `AmazonECSTaskExecutionRolePolicy` + CloudWatch permissions.
  - Task Role: Scoped policies for DynamoDB, RDS, SSM Parameter Store, S3, SNS, and CloudWatch.
- **Fargate Task Definitions & Services**:
  - 4 Task Definitions (256 CPU, 512 MiB memory) logging to `/ecs/ecommerce-*` CloudWatch groups.
  - 4 Fargate Services deployed in private app subnets, registered with target groups and `ecs-tasks-sg`.
  - Service lifecycle configured with `ignore_changes = [desired_count]` to preserve dynamic auto-scaling decisions.
- **Dynamic Target Tracking Auto-Scaling**:
  - Registered Scalable Targets for all 4 microservices (Min: 0, Max: 4 tasks).
  - CPU Utilization Policy: Targets 70% average CPU across tasks (`scale_out_cooldown: 60s`, `scale_in_cooldown: 300s`).
  - Memory Utilization Policy: Targets 80% average Memory utilization.
- **FinOps Scheduled Scaling (Night-Mode Scale to 0)**:
  - Night Scale-Down: Automatically scales tasks to `0` at 22:00 UTC daily (`cron(0 22 * * ? *)`), saving ~42% on Fargate costs.
  - Morning Scale-Up: Automatically wakes up tasks to `min = 1, max = 4` at 08:00 UTC daily (`cron(0 8 * * ? *)`).

### Phase 5: API Gateway & Secure Edge (`09-apigateway`)
- **VPC Link**: `ecommerce-vpc-link` attached to private app subnets and internal ALB.
- **HTTP API (v2)**: `ecommerce-api` with `$default` auto-deploy stage.
- **Cognito JWT Authorizer**: Validates `$request.header.Authorization` against the Cognito User Pool.
- **Routes**:
  - `GET /products` (Public catalog, no authentication).
  - `OPTIONS /{proxy+}` (CORS Preflight, no authentication, avoids 401 preflight challenge).
  - `ANY /{proxy+}` (Protected proxy with JWT authorizer).
- **Native CORS Configuration**:
  - Allowed Origins: `https://mycloudhomelab.click`, `https://www.mycloudhomelab.click`, `https://ecommerce.mycloudhomelab.click`, `http://localhost:3000`.
  - Allowed Headers: `*`, `Authorization`, `Content-Type`, `x-user-email`, `x-user-id`, `x-user-name`.

### Phase 6: Frontend Static Hosting & CDN (`10-frontend`)
- **S3 Bucket**: `ecommerce-frontend-assets-${account_id}` with public access block and SSE-S3 encryption.
- **CloudFront OAC**: Secure authenticated Origin Access Control.
- **CloudFront Distribution**:
  - Caching optimized policy (`658327ea-f89d-4fab-a63d-7e88639e58f6`).
  - Redirect HTTP to HTTPS.
  - Single Page Application (SPA) Error Responses: 403 and 404 redirected to `/index.html` with status `200`.

### Phase 7: Custom Domain (Route 53) & Public TLS (`ACM`)
- **Idempotent Hosted Zone Lookup**: Dynamic query of existing public zone `mycloudhomelab.click`.
- **AWS Certificate Manager (ACM)**:
  - Issued in `us-east-1` for `mycloudhomelab.click` with SANs `www.mycloudhomelab.click` and `ecommerce.mycloudhomelab.click`.
  - Automated DNS validation using Route 53 CNAME records.
- **CloudFront Aliases & TLS Binding**:
  - Aliases: `mycloudhomelab.click`, `www.mycloudhomelab.click`, `ecommerce.mycloudhomelab.click`.
  - Viewer Certificate: Custom ACM certificate with SNI-only and TLS 1.2+ (`TLSv1.2_2021`).
- **Route 53 A-Alias Records**:
  - Apex `A` record (`mycloudhomelab.click`) -> CloudFront distribution.
  - Subdomain `A` records (`www`, `ecommerce`) -> CloudFront distribution.
- **Sensitive Variables Isolation**:
  - Database password, domain names, and subdomains isolated in `terraform.tfvars`.

### Phase 8: Asynchronous SQS Order Processor Lambda (`11-order-processor`)
- **AWS Lambda Function**: `ecommerce-order-processor-dev` running in Python 3.11 with VPC access (Private App subnets).
- **SQS Event Source Mapping**: Automatically triggered by `ecommerce-order-shipping` queue with batch size 5.
- **Order Fulfillment Logic**:
  - Parses incoming order payloads published by `order-service` via SNS $\to$ SQS.
  - Generates simulated carrier tracking numbers (`TRK-US-XXXXXXXXXX`).
  - Connects to RDS PostgreSQL via pure-Python `pg8000` driver and advances order status from `'Order Placed'` to `'Shipped'`.
- **Security & IAM**:
  - VPC ENI execution permissions (`AWSLambdaVPCAccessExecutionRole`).
  - Scoped SQS message consumption permissions (`sqs:ReceiveMessage`, `sqs:DeleteMessage`).
  - Security group rule granting Lambda port 5432 ingress into RDS PostgreSQL.

### Phase 9: Observability, CloudWatch Dashboard & Alarms (`12-monitoring`)
- **Executive Operations Dashboard**: `ecommerce-dev-dashboard` visualizing real-time metrics across:
  - **API Gateway**: Traffic count, 4xx/5xx error rates, p50/p95/p99 latencies, and ALB backend integration latency.
  - **ECS Fargate**: Per-service CPU and Memory utilization with dynamic auto-scaling threshold lines (70% and 80%).
  - **RDS PostgreSQL**: CPU utilization, active client connections, and free storage space.
  - **SQS & Lambda**: Order queue depth (pending vs. in-flight messages), Lambda invocations, duration, and error rates.
- **Critical CloudWatch Metric Alarms**:
  - API Gateway 5xx Server Error Spike (> 5 errors in 5 min).
  - High RDS CPU Utilization (> 85% for 10 min).
  - Order Processor Lambda Failures (> 0 errors).
- **Centralized Alerting**: `ecommerce-alerts-dev` SNS topic dispatching alarms with optional email notifications.

### Phase 10: Distributed Tracing with AWS X-Ray
- **Zero-Egress X-Ray PrivateLink Endpoint**: `aws_vpc_endpoint.xray` deployed in private app subnets, ensuring container traces travel directly over AWS private network without traversing the internet.
- **ECS Task Roles Instrumentation**: Attached `AWSXRayDaemonWriteAccess` policy to ECS tasks, authorizing microservices to emit telemetry spans.
- **Serverless Active Tracing**: Configured `tracing_config { mode = "Active" }` on Order Processor Lambda with `AWSXRayDaemonWriteAccess` execution role permissions.
- **End-to-End Service Map**: Automatically generates cross-service dependency graphs (API Gateway $\to$ ALB $\to$ ECS Services $\to$ RDS / DynamoDB / SNS $\to$ SQS $\to$ Lambda) highlighting per-hop response times.

---


### Phase 11: FinOps Financial Engineering & Governance (`13-finops`)
* **Module**: `modules/13-finops`
* **AWS Budgets & CloudWatch Billing Alarm**:
  - `aws_budgets_budget.cost_budget`: Enforces a hard **$25.00/month** spending cap.
    - Alert 1 (Actual Spend): Fires when month-to-date actual charges cross **80% ($20.00)**.
    - Alert 2 (Forecasted Spend): Fires if AWS Machine Learning predicts monthly charges will reach **100% ($25.00)**.
  - `aws_cloudwatch_metric_alarm.billing_alarm`: Monitors CloudWatch metric `EstimatedCharges` in `us-east-1` with a **$20.00** threshold, publishing alerts to an SNS topic.
* **Fargate Spot Compute Optimization (`modules/08-ecs`)**:
  - Added `aws_ecs_cluster_capacity_providers` configuring `FARGATE_SPOT` with 100% weight, replacing standard On-Demand Fargate.
  - All 4 microservices (`product-service`, `cart-service`, `user-service`, `order-service`) use `capacity_provider_strategy`.
  - Delivers an immediate **~70% compute cost reduction** using AWS spare capacity.
* **S3 Storage Lifecycle Hygiene (`modules/10-frontend`)**:
  - Added `aws_s3_bucket_lifecycle_configuration` to the frontend bucket.
  - Non-current file versions expire and are deleted after **14 days**.
  - Incomplete multipart uploads are aborted and removed after **7 days**.
  - Eliminates "zombie" storage costs caused by repeated deployments and media uploads.
* **Nightly Auto-Snooze & Wakeup Workflow (`.github/workflows/finops-snooze.yml`)**:
  - Auto-snoozes all 4 ECS services (`desired_count = 0`) at 20:00 UTC Monday–Friday (`0 20 * * 1-5`).
  - Auto-wakes all 4 ECS services (`desired_count = 1`) at 08:00 UTC Monday–Friday (`0 8 * * 1-5`).
  - Manual trigger via `workflow_dispatch` [snooze, wake].
  - Cuts active compute hours from 168 hrs/week to ~60 hrs/week (**~65% off-hours compute savings**).
* **Infracost Shift-Left PR Cost Estimator (`.github/workflows/terraform-plan.yml`)**:
  - On every Pull Request, Infracost calculates the monthly cost delta of proposed Terraform changes.
  - Posts an automated markdown table to the PR comment thread before code is merged.
  - Guarded with `if: ${{ secrets.INFRACOST_API_KEY != '' }}` so builds remain green even if optional key is not set.

### 💰 Total Estimated Cost Impact

| Category | Baseline Cost (On-Demand 24/7) | Optimized Cost (FinOps Active) | Monthly Savings |
| :--- | :--- | :--- | :--- |
| **ECS Microservices Compute** | ~$48.00/mo | ~$5.76/mo (Spot + Snooze) | **~88% compute savings** |
| **S3 Storage & Multi-Versions** | ~$2.50/mo | ~$0.30/mo (Lifecycle rule) | **~88% storage savings** |
| **Budget Safety Net** | Unlimited runaway risk | **Capped at $25.00/mo** | **100% overrun protection** |

---

## 4. Application Source Code & Deployment Automation Pipeline

### 4.1 Master End-to-End One-Click Deployment Pipeline (`scripts/deploy-all.sh`)
The master orchestration script automatically executes the entire lifecycle in the correct dependency order:
```bash
cd /home/vagrant/terraform-projects/terraform-aws-projets/terraform-ecommerce
./scripts/deploy-all.sh
```

**Step-by-Step Execution Sequence**:
1. **Infrastructure**: Runs `terraform init` and `terraform apply -auto-approve` inside `environments/dev`.
2. **Microservices Containers**: Automatically invokes `./scripts/build-and-push-images.sh` to build and push all 4 microservices to Amazon ECR.
3. **Product Images & Database**: Uploads product images to `s3://<bucket>/images/`, updates `products.json` with the CloudFront HTTPS base URL, and populates the DynamoDB table `ecommerce-products`.
4. **Frontend SPA Application**: Runs `./scripts/deploy-frontend.sh` to configure `aws-config.js`, build React assets, sync to S3, and invalidate CloudFront edge caches.
5. **Endpoint Summary**: Emits the final live URLs for the primary custom domain (`https://mycloudhomelab.click`), subdomains, CloudFront distribution, and API Gateway.

### 4.2 Automated Docker Container Pipeline (`scripts/build-and-push-images.sh`)
Builds and pushes all 4 microservices to Amazon ECR:
```bash
./scripts/build-and-push-images.sh
```
1. Authenticates local Docker daemon to ECR via `aws ecr get-login-password`.
2. Builds `product-service`, `cart-service`, `user-service`, and `order-service` Docker images.
3. Tags and pushes each image to its respective ECR repository.

### 4.3 Automated Catalog & Images Seeding (`data/`)
```bash
cd /home/vagrant/terraform-projects/terraform-aws-projets/terraform-ecommerce/data

# 1. Discover the S3 frontend assets bucket
BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?contains(Name, 'ecommerce-frontend-')].Name" --output text | awk '{print $1}')

# 2. Upload sample product images to s3://$BUCKET_NAME/images/
./upload-images-to-s3.sh "$BUCKET_NAME" us-east-1

# 3. Update products.json to reference CloudFront / Domain HTTPS image URLs
CLOUDFRONT_URL=$(cd ../environments/dev && terraform output -raw cloudfront_url)
./update-product-image-urls.sh "$CLOUDFRONT_URL"

# 4. Batch-load products from products.json into DynamoDB table ecommerce-products
./load-products.sh us-east-1

# 5. Verify the seeded items in DynamoDB
aws dynamodb scan \
  --table-name ecommerce-products \
  --region us-east-1 \
  --query "Items[*].[product_id.S, name.S, price.N, category.S]" \
  --output table
```

### 4.4 Automated Frontend Configuration (`scripts/configure-frontend.sh`)
Injects live Cognito User Pool ID, Client ID, and API Gateway URL into `frontend/react-app/src/aws-config.js`:
```bash
./scripts/configure-frontend.sh
```

### 4.5 Automated Frontend Build & Deployment (`scripts/deploy-frontend.sh`)
Builds and uploads the production bundle:
```bash
./scripts/deploy-frontend.sh
```
1. Injects latest configuration via `configure-frontend.sh`.
2. Executes `npm install` and `npm run build`.
3. Synchronizes `build/` to S3 with `--delete --exclude "images/*"`.
4. Invalidates CloudFront cache (`/*`) for immediate global propagation.

---

## 5. Verification Plan & Manual CLI Verification Commands

Execute these commands directly on the Vagrant VM (`vagrant@terraform:~/terraform-projects/terraform-aws-projets/terraform-ecommerce/environments/dev`) to verify every layer:

### Phase 1: VPC & VPC Endpoints Verification
```bash
# 1. Verify VPC ID and Subnets
aws ec2 describe-vpcs \
  --vpc-ids $(terraform output -raw vpc_id) \
  --query "Vpcs[*].[VpcId, CidrBlock, State]" --output table

# 2. Verify VPC Endpoints Status (7 endpoints)
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)" \
  --query "VpcEndpoints[*].[ServiceName, VpcEndpointType, State]" --output table
```

### Phase 2: Database, Auth & Messaging Verification
```bash
# 1. Verify DynamoDB Tables
aws dynamodb list-tables --region us-east-1 --output table

# 2. Verify RDS Instance Status & Endpoint
aws rds describe-db-instances \
  --db-instance-identifier ecommercedb-instance \
  --region us-east-1 \
  --query "DBInstances[*].[DBInstanceIdentifier, DBInstanceStatus, Endpoint.Address, EngineVersion]" --output table

# 3. Verify Cognito User Pool & App Client
aws cognito-idp describe-user-pool \
  --user-pool-id $(terraform output -raw cognito_user_pool_id) \
  --query "UserPool.[Id, Name, Status]" --output table

# 4. Verify SNS Topic & SQS Queue
aws sns list-topics --query "Topics[?contains(TopicArn, 'ecommerce')].TopicArn" --output text
aws sqs list-queues --queue-name-prefix ecommerce --query "QueueUrls" --output table

# 5. Verify SSM Parameters
aws ssm get-parameters-by-path --path /ecommerce/dev/ --query "Parameters[*].[Name, Type]" --output table
```

### Phase 3: Internal ALB & ECR Verification
```bash
# 1. Verify Internal ALB State and Scheme
aws elbv2 describe-load-balancers \
  --load-balancer-arns $(terraform output -raw alb_arn) \
  --query "LoadBalancers[*].[DNSName, Scheme, State.Code]" --output table

# 2. Verify 4 Target Groups and Health Checks
aws elbv2 describe-target-groups \
  --query "TargetGroups[?contains(TargetGroupName, 'service-tg')].[TargetGroupName, Port, Protocol, HealthCheckPath]" --output table

# 3. Verify 4 ECR Repositories
aws ecr describe-repositories \
  --query "repositories[?contains(repositoryName, 'ecommerce/')].[repositoryName, repositoryUri]" --output table
```

### Phase 4: ECS Fargate Cluster & Services Verification
```bash
# 1. Verify ECS Cluster
aws ecs describe-clusters \
  --clusters ecommerce-cluster \
  --region us-east-1 \
  --query "clusters[*].[clusterName, status, activeServicesCount, runningTasksCount]" --output table

# 2. Verify 4 Fargate Services
aws ecs list-services --cluster ecommerce-cluster --region us-east-1 --output table

# 3. Verify Task Definitions
for SVC in product-service cart-service user-service order-service; do
  aws ecs describe-task-definition \
    --task-definition ecommerce-$SVC \
    --query "taskDefinition.[family, revision, status, containerDefinitions[0].portMappings[0].containerPort]" --output table
done

# 4. Verify CloudWatch Log Groups
aws logs describe-log-groups --log-group-name-prefix /ecs/ --query "logGroups[*].[logGroupName, retentionInDays]" --output table
```

### Phase 5: HTTP API Gateway Verification
```bash
# 1. Verify API Gateway and VPC Link
API_ID=$(terraform output -raw api_gateway_id)
echo "API ID: $API_ID"
echo "Invoke URL: $(terraform output -raw api_gateway_url)"

aws apigatewayv2 get-vpc-links \
  --query "Items[?Name=='ecommerce-vpc-link'].[VpcLinkId, Name, VpcLinkStatus]" --output table

# 2. Verify Routes and Authorizers
aws apigatewayv2 get-routes \
  --api-id $API_ID \
  --query "Items[*].[RouteKey, AuthorizationType, Target]" --output table

# 3. Test Public vs Protected Routes
API_URL=$(terraform output -raw api_gateway_url)

# Should return 200 (Public catalog):
curl -s -o /dev/null -w "%{http_code}\n" "${API_URL}/products"

# Should return 401 (Protected by Cognito JWT):
curl -s -o /dev/null -w "%{http_code}\n" "${API_URL}/cart"

# Should return 200 (CORS Preflight):
curl -s -X OPTIONS "${API_URL}/cart" \
  -H "Origin: https://mycloudhomelab.click" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: authorization" \
  -o /dev/null -w "%{http_code}\n"
```

### Phase 6 & 7: S3, CloudFront, Route 53 & ACM Custom Domain Verification
```bash
# 1. Verify S3 Frontend Bucket
BUCKET_NAME=$(terraform output -raw frontend_bucket_name)
aws s3api head-bucket --bucket "$BUCKET_NAME"

# 2. Verify ACM Certificate Status
CERT_ARN=$(terraform output -raw certificate_arn)
aws acm describe-certificate \
  --certificate-arn "$CERT_ARN" \
  --query "Certificate.[DomainName, Status, SubjectAlternativeNames]" --output table

# 3. Verify CloudFront Distribution Aliases & Custom Certificate
DIST_ID=$(terraform output -raw cloudfront_distribution_id)
aws cloudfront get-distribution --id "$DIST_ID" \
  --query "Distribution.[Status, DomainName, DistributionConfig.Aliases.Items, DistributionConfig.ViewerCertificate.Certificate]" --output table

# 4. Verify Route 53 DNS Records
for DOMAIN in mycloudhomelab.click www.mycloudhomelab.click ecommerce.mycloudhomelab.click; do
  echo "Checking DNS resolution for $DOMAIN:"
  dig +short A "$DOMAIN"
done

# 5. Verify HTTPS Responses Across Custom Domains
for DOMAIN in mycloudhomelab.click www.mycloudhomelab.click ecommerce.mycloudhomelab.click; do
  echo "Testing HTTPS connection to $DOMAIN:"
  curl -I "https://${DOMAIN}" | head -n 5
done
```

### Phase 8: Asynchronous SQS Order Processor Lambda Verification
```bash
# 1. Verify Lambda Function State and Configuration
LAMBDA_NAME=$(terraform output -raw order_processor_lambda_name)
aws lambda get-function \
  --function-name "$LAMBDA_NAME" \
  --query "Configuration.[FunctionName, Runtime, State, Timeout, MemorySize]" \
  --output table

# 2. Verify SQS Event Source Mapping
aws lambda list-event-source-mappings \
  --function-name "$LAMBDA_NAME" \
  --query "EventSourceMappings[*].[UUID, EventSourceArn, State, BatchSize]" \
  --output table

# 3. Verify Lambda CloudWatch Log Group
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/lambda/${LAMBDA_NAME}" \
  --query "logGroups[*].[logGroupName, retentionInDays]" \
  --output table

# 4. View Recent Order Processing Execution Logs
aws logs filter-log-events \
  --log-group-name "/aws/lambda/${LAMBDA_NAME}" \
  --filter-pattern "Processing Order" \
  --query "events[*].[timestamp, message]" \
  --output table
```

### Phase 9: Observability, CloudWatch Dashboard & Alarms Verification
```bash
# 1. Verify CloudWatch Dashboard Existence & Structure
DASHBOARD_NAME=$(terraform output -raw cloudwatch_dashboard_name)
aws cloudwatch get-dashboard \
  --dashboard-name "$DASHBOARD_NAME" \
  --query "DashboardName" \
  --output text

# 2. Print Direct AWS Management Console Dashboard URL
echo "Dashboard URL: $(terraform output -raw cloudwatch_dashboard_url)"

# 3. Verify Configured CloudWatch Alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix "ecommerce-" \
  --query "MetricAlarms[*].[AlarmName, StateValue, MetricName, Threshold]" \
  --output table

# 4. Verify SNS Alert Topic
aws sns get-topic-attributes \
  --topic-arn $(terraform output -raw alerts_sns_topic_arn) \
  --query "Attributes.TopicArn" \
  --output text
```

### Phase 10: Distributed Tracing with AWS X-Ray Verification
```bash
# 1. Verify X-Ray VPC Interface Endpoint Status
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)" "Name=service-name,Values=*xray*" \
  --query "VpcEndpoints[*].[ServiceName, VpcEndpointType, State]" \
  --output table

# 2. Verify Lambda Active Tracing Configuration
aws lambda get-function-configuration \
  --function-name $(terraform output -raw order_processor_lambda_name) \
  --query "TracingConfig.Mode" \
  --output text

# 3. Retrieve Live Service Graph Summary via AWS X-Ray
aws xray get-service-graph \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s) \
  --query "Services[*].[Name, Type, State]" \
  --output table
```

---


### Phase 11: FinOps Financial Engineering Verification & Test Steps

#### Test 11.1: Verify AWS Monthly Budget & Limit
```bash
# 1. Query the active AWS Budget details ($25.00 limit)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws budgets describe-budgets \
  --account-id "$ACCOUNT_ID" \
  --query "Budgets[?BudgetName=='ecommerce-monthly-budget'].[BudgetName, BudgetLimit.Amount, BudgetLimit.Unit, TimeUnit]" \
  --output table

# 2. Verify Budget Notification Thresholds (80% actual & 100% forecast)
aws budgets describe-notifications-for-budget \
  --account-id "$ACCOUNT_ID" \
  --budget-name "ecommerce-monthly-budget" \
  --query "Notifications[*].[NotificationType, ComparisonOperator, Threshold, ThresholdType]" \
  --output table
```

#### Test 11.2: Verify CloudWatch Billing Alarm
```bash
# 1. Verify Billing Alarm State & Threshold ($20.00)
aws cloudwatch describe-alarms \
  --alarm-names "ecommerce-billing-alarm-monthly" \
  --query "MetricAlarms[*].[AlarmName, StateValue, MetricName, Threshold]" \
  --output table
```

#### Test 11.3: Verify ECS Services on Fargate Spot Capacity Provider
```bash
# 1. Confirm cluster capacity providers include FARGATE_SPOT
aws ecs describe-clusters \
  --clusters ecommerce-cluster \
  --query "clusters[0].capacityProviders" \
  --output json

# 2. Confirm all 4 ECS services use FARGATE_SPOT with 100% weight
aws ecs describe-services \
  --cluster ecommerce-cluster \
  --services ecommerce-product-service ecommerce-cart-service ecommerce-user-service ecommerce-order-service \
  --query "services[*].[serviceName, capacityProviderStrategy[0].capacityProvider, capacityProviderStrategy[0].weight]" \
  --output table

# 3. Check running tasks on Fargate Spot
aws ecs list-tasks --cluster ecommerce-cluster --desired-status RUNNING
```

#### Test 11.4: Verify S3 Lifecycle Configuration Rules
```bash
# 1. Inspect S3 Lifecycle Configuration on frontend bucket
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3api get-bucket-lifecycle-configuration \
  --bucket "ecommerce-frontend-${ACCOUNT_ID}" \
  --query "Rules[*].[ID, Status, NoncurrentVersionExpiration.NoncurrentDays, AbortIncompleteMultipartUpload.DaysAfterInitiation]" \
  --output table
```

#### Test 11.5: Test and Confirm Nightly Auto-Snooze & Wakeup Automation
```bash
# 1. Test Snooze Action (Scale down to 0)
for svc in ecommerce-product-service ecommerce-cart-service ecommerce-user-service ecommerce-order-service; do
  aws ecs update-service --cluster ecommerce-cluster --service "$svc" --desired-count 0 --region us-east-1 > /dev/null
done
echo "Snooze command issued. Waiting 10s for tasks to spin down..."
sleep 10
aws ecs describe-services --cluster ecommerce-cluster \
  --services ecommerce-product-service ecommerce-cart-service ecommerce-user-service ecommerce-order-service \
  --query "services[*].[serviceName, desiredCount, runningCount]" --output table

# 2. Test Wakeup Action (Restore back to 1)
for svc in ecommerce-product-service ecommerce-cart-service ecommerce-user-service ecommerce-order-service; do
  aws ecs update-service --cluster ecommerce-cluster --service "$svc" --desired-count 1 --region us-east-1 > /dev/null
done
echo "Wakeup command issued. Services restored to desired count 1."
aws ecs describe-services --cluster ecommerce-cluster \
  --services ecommerce-product-service ecommerce-cart-service ecommerce-user-service ecommerce-order-service \
  --query "services[*].[serviceName, desiredCount]" --output table
```

#### Test 11.6: Verify Infracost Shift-Left PR Cost Estimator
```bash
# 1. Verify workflow integration
grep -A 15 "infracost" .github/workflows/terraform-plan.yml
```
