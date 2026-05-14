
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

module "dynamodb" {
  source = "./modules/dynamodb"

  table_name       = var.table_name
  secondary_region = var.secondary_region
}

module "iam" {
  source = "./modules/iam"

  project_name     = var.project_name
  environment      = var.environment
  table_arn        = module.dynamodb.table_arn
  table_name       = module.dynamodb.table_name
  primary_region   = var.primary_region
  secondary_region = var.secondary_region
}

module "read_lambda_primary" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${var.environment}-read-primary"
  handler       = "read_function.lambda_handler"
  source_dir    = "../lambda/read"

  role_arn   = module.iam.lambda_role_arn
  table_name = module.dynamodb.table_name
}

module "write_lambda_primary" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-${var.environment}-write-primary"
  handler       = "write_function.lambda_handler"
  source_dir    = "../lambda/write"

  role_arn   = module.iam.lambda_role_arn
  table_name = module.dynamodb.table_name
}


module "read_lambda_secondary" {
  source = "./modules/lambda"

  providers = {
    aws = aws.secondary
  }

  function_name = "${var.project_name}-${var.environment}-read-secondary"
  handler       = "read_function.lambda_handler"
  source_dir    = "../lambda/read"

  role_arn   = module.iam.lambda_role_arn
  table_name = module.dynamodb.table_name
}

module "write_lambda_secondary" {
  source = "./modules/lambda"

  providers = {
    aws = aws.secondary
  }

  function_name = "${var.project_name}-${var.environment}-write-secondary"
  handler       = "write_function.lambda_handler"
  source_dir    = "../lambda/write"

  role_arn   = module.iam.lambda_role_arn
  table_name = module.dynamodb.table_name
}

module "acm_primary" {
  source = "./modules/acm"

  domain_name   = var.domain_name
  api_subdomain = var.api_subdomain
  zone_id       = data.aws_route53_zone.main.zone_id
}

module "acm_secondary" {
  source = "./modules/acm"

  providers = {
    aws = aws.secondary
  }

  domain_name   = var.domain_name
  api_subdomain = var.api_subdomain
  zone_id       = data.aws_route53_zone.main.zone_id
}

module "api_gateway_primary" {
  source = "./modules/apigateway"

  api_name = "${var.project_name}-${var.environment}-api-primary"

  custom_domain_name = module.acm_primary.api_domain_name
  certificate_arn    = module.acm_primary.certificate_arn

  read_lambda_name       = module.read_lambda_primary.lambda_function_name
  read_lambda_invoke_arn = module.read_lambda_primary.invoke_arn

  write_lambda_name       = module.write_lambda_primary.lambda_function_name
  write_lambda_invoke_arn = module.write_lambda_primary.invoke_arn
  enable_cognito_auth     = true
  cognito_user_pool_arn   = module.cognito_primary.user_pool_arn
}
module "api_gateway_secondary" {
  source = "./modules/apigateway"

  providers = {
    aws = aws.secondary
  }

  api_name = "${var.project_name}-${var.environment}-api-secondary"

  custom_domain_name = module.acm_secondary.api_domain_name
  certificate_arn    = module.acm_secondary.certificate_arn

  read_lambda_name       = module.read_lambda_secondary.lambda_function_name
  read_lambda_invoke_arn = module.read_lambda_secondary.invoke_arn

  write_lambda_name       = module.write_lambda_secondary.lambda_function_name
  write_lambda_invoke_arn = module.write_lambda_secondary.invoke_arn
  enable_cognito_auth     = true
  cognito_user_pool_arn   = module.cognito_primary.user_pool_arn
}



module "route53_failover" {
  source = "./modules/route53"

  zone_id = data.aws_route53_zone.main.zone_id

  record_name = "${var.api_subdomain}.${var.domain_name}"

  primary_domain_name = module.api_gateway_primary.regional_domain_name
  primary_zone_id     = module.api_gateway_primary.regional_zone_id

  secondary_domain_name = module.api_gateway_secondary.regional_domain_name
  secondary_zone_id     = module.api_gateway_secondary.regional_zone_id

  primary_health_check_fqdn = replace(
    replace(module.api_gateway_primary.invoke_url, "https://", ""),
    "/prod",
    ""
  )
}

module "s3_frontend" {
  source = "./modules/s3-frontend"

  bucket_name     = var.frontend_bucket_name
  index_file_path = "../frontend/index.html"
}


module "cognito_primary" {
  source = "./modules/cognito"

  project_name = var.project_name
  environment  = var.environment
}
