# -------------------------------------------------------------
# Module 01: VPC & Networking
# -------------------------------------------------------------
module "vpc" {
  source = "../../modules/01-vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = "10.10.0.0/16"
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]

  public_subnet_cidrs      = ["10.10.1.0/24", "10.10.2.0/24"]
  private_app_subnet_cidrs = ["10.10.11.0/24", "10.10.12.0/24"]
  private_db_subnet_cidrs  = ["10.10.21.0/24", "10.10.22.0/24"]
  aws_region               = var.aws_region
}

# -------------------------------------------------------------
# Module 02: Databases (RDS PostgreSQL + DynamoDB Tables)
# -------------------------------------------------------------
module "database" {
  source = "../../modules/02-database"

  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  private_db_subnet_ids = module.vpc.private_db_subnet_ids
  rds_security_group_id = module.vpc.rds_security_group_id
  db_password           = var.db_password
}

# -------------------------------------------------------------
# Module 03: Authentication (AWS Cognito)
# -------------------------------------------------------------
module "auth" {
  source = "../../modules/03-auth"

  project_name = var.project_name
  environment  = var.environment
}

# -------------------------------------------------------------
# Module 04: Notification (SNS + SQS)
# -------------------------------------------------------------
module "notification" {
  source = "../../modules/05-notification"

  project_name = var.project_name
  environment  = var.environment
}

# -------------------------------------------------------------
# Module 05: Security & Configuration (SSM Parameter Store)
# -------------------------------------------------------------
module "security" {
  source = "../../modules/04-security"

  project_name  = var.project_name
  environment   = var.environment
  aws_region    = var.aws_region
  db_host       = module.database.rds_address
  db_password   = var.db_password
  sns_topic_arn = module.notification.sns_topic_arn
}

# -------------------------------------------------------------
# Module 06: Internal Application Load Balancer
# -------------------------------------------------------------
module "alb" {
  source = "../../modules/06-alb"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  alb_security_group_id  = module.vpc.alb_security_group_id
}

# -------------------------------------------------------------
# Module 07: Container Registries (Amazon ECR)
# -------------------------------------------------------------
module "ecr" {
  source = "../../modules/07-ecr"

  project_name = var.project_name
  environment  = var.environment
}

# -------------------------------------------------------------
# Module 08: ECS Cluster & Fargate Services
# -------------------------------------------------------------
module "ecs" {
  source = "../../modules/08-ecs"

  project_name                = var.project_name
  environment                 = var.environment
  aws_region                  = var.aws_region
  private_app_subnet_ids      = module.vpc.private_app_subnet_ids
  ecs_tasks_security_group_id = module.vpc.ecs_tasks_security_group_id

  product_target_group_arn = module.alb.product_target_group_arn
  cart_target_group_arn    = module.alb.cart_target_group_arn
  user_target_group_arn    = module.alb.user_target_group_arn
  order_target_group_arn   = module.alb.order_target_group_arn

  ecr_repository_urls = module.ecr.repository_urls
}

# -------------------------------------------------------------
# Module 09: HTTP API Gateway Layer
# -------------------------------------------------------------
module "apigateway" {
  source = "../../modules/09-apigateway"

  project_name               = var.project_name
  environment                = var.environment
  aws_region                 = var.aws_region
  vpc_id                     = module.vpc.vpc_id
  private_app_subnet_ids     = module.vpc.private_app_subnet_ids
  alb_listener_arn           = module.alb.listener_arn
  cognito_user_pool_endpoint = module.auth.cognito_user_pool_endpoint
  cognito_client_id          = module.auth.cognito_client_id
  cors_allowed_origins = concat(
    [
      "https://${var.domain_name}",
      "http://localhost:3000"
    ],
    [for sub in var.subdomains : "https://${sub}"]
  )
}

# -------------------------------------------------------------
# Module 10: Frontend SPA Hosting (S3 + CloudFront + Route53 + ACM)
# -------------------------------------------------------------
module "frontend" {
  source = "../../modules/10-frontend"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.domain_name
  subdomains   = var.subdomains
}

# -------------------------------------------------------------
# Module 11: Asynchronous SQS Order Processor Lambda
# -------------------------------------------------------------
module "order_processor" {
  source = "../../modules/11-order-processor"

  project_name           = var.project_name
  environment            = var.environment
  aws_region             = var.aws_region
  sqs_queue_arn          = module.notification.sqs_queue_arn
  vpc_id                 = module.vpc.vpc_id
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  rds_security_group_id  = module.vpc.rds_security_group_id
  db_host                = module.database.rds_address
  db_password            = var.db_password
}

# -------------------------------------------------------------
# Module 12: Observability, CloudWatch Dashboard & Alarms
# -------------------------------------------------------------
module "monitoring" {
  source = "../../modules/12-monitoring"

  project_name         = var.project_name
  environment          = var.environment
  aws_region           = var.aws_region
  ecs_cluster_name     = module.ecs.cluster_name
  api_gateway_id       = module.apigateway.api_id
  alb_arn_suffix       = module.alb.alb_arn_suffix
  sqs_queue_name       = module.notification.sqs_queue_name
  lambda_function_name = module.order_processor.lambda_function_name
}


