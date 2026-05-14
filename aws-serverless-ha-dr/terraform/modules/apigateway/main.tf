terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_region" "current" {}

resource "aws_api_gateway_rest_api" "this" {
  name = var.api_name

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "read" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "read"
}

resource "aws_api_gateway_resource" "write" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "write"
}

# resource "aws_api_gateway_method" "read_get" {
#   rest_api_id   = aws_api_gateway_rest_api.this.id
#   resource_id   = aws_api_gateway_resource.read.id
#   http_method   = "GET"
#   authorization = "NONE"
# }

resource "aws_api_gateway_method" "read_get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.read.id
  http_method   = "GET"
  authorization = var.enable_cognito_auth ? "COGNITO_USER_POOLS" : "NONE"
  authorizer_id = var.enable_cognito_auth ? aws_api_gateway_authorizer.cognito[0].id : null
}

# resource "aws_api_gateway_method" "write_post" {
#   rest_api_id   = aws_api_gateway_rest_api.this.id
#   resource_id   = aws_api_gateway_resource.write.id
#   http_method   = "POST"
#   authorization = "NONE"
# }

resource "aws_api_gateway_method" "write_post" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.write.id
  http_method   = "POST"
  authorization = var.enable_cognito_auth ? "COGNITO_USER_POOLS" : "NONE"
  authorizer_id = var.enable_cognito_auth ? aws_api_gateway_authorizer.cognito[0].id : null
}

resource "aws_api_gateway_integration" "read_lambda" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.read.id
  http_method = aws_api_gateway_method.read_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.read_lambda_invoke_arn
}

resource "aws_api_gateway_integration" "write_lambda" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.write.id
  http_method = aws_api_gateway_method.write_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.write_lambda_invoke_arn
}

resource "aws_lambda_permission" "allow_api_gateway_read" {
  statement_id  = "AllowExecutionFromAPIGatewayRead"
  action        = "lambda:InvokeFunction"
  function_name = var.read_lambda_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_write" {
  statement_id  = "AllowExecutionFromAPIGatewayWrite"
  action        = "lambda:InvokeFunction"
  function_name = var.write_lambda_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "this" {
  depends_on = [
    aws_api_gateway_integration.read_lambda,
    aws_api_gateway_integration.write_lambda
  ]

  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.read.id,
      aws_api_gateway_resource.write.id,
      aws_api_gateway_method.read_get.id,
      aws_api_gateway_method.write_post.id,
      aws_api_gateway_integration.read_lambda.id,
      aws_api_gateway_integration.write_lambda.id,
      var.enable_cognito_auth,
      var.cognito_user_pool_arn
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.stage_name
}

resource "aws_api_gateway_domain_name" "this" {
  domain_name              = var.custom_domain_name
  regional_certificate_arn = var.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "this" {
  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this.domain_name
}


resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    throttling_rate_limit  = var.throttling_rate_limit
    throttling_burst_limit = var.throttling_burst_limit
    metrics_enabled        = true
  }
}

resource "aws_api_gateway_authorizer" "cognito" {
  count = var.enable_cognito_auth ? 1 : 0

  name          = "${var.api_name}-cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.this.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [var.cognito_user_pool_arn]

  identity_source = "method.request.header.Authorization"
}
