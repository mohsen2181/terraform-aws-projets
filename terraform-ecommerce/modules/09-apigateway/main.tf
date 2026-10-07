# -------------------------------------------------------------
# 1. Security Group for VPC Link
# -------------------------------------------------------------

resource "aws_security_group" "vpclink_sg" {
  name        = "${var.project_name}-vpclink-sg"
  description = "Security group for VPC Link to ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from API Gateway"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from API Gateway"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound to anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-vpclink-sg"
    Environment = var.environment
  }
}

# -------------------------------------------------------------
# 2. VPC Link for HTTP APIs (v2)
# -------------------------------------------------------------

resource "aws_apigatewayv2_vpc_link" "link" {
  name               = "${var.project_name}-vpc-link"
  security_group_ids = [aws_security_group.vpclink_sg.id]
  subnet_ids         = var.private_app_subnet_ids

  tags = {
    Name        = "${var.project_name}-vpc-link"
    Environment = var.environment
  }
}

# -------------------------------------------------------------
# 3. HTTP API Gateway & Native CORS Configuration
# -------------------------------------------------------------

resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  description   = "eCommerce HTTP API Gateway"

  cors_configuration {
    allow_origins = var.cors_allowed_origins
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = [
      "*",
      "Authorization",
      "Content-Type",
      "X-Amz-Date",
      "X-Api-Key",
      "X-Amz-Security-Token",
      "x-user-email",
      "x-user-id",
      "x-user-name"
    ]
    max_age = 300
  }

  tags = {
    Name        = "${var.project_name}-api"
    Environment = var.environment
  }
}

# -------------------------------------------------------------
# 4. Default Stage with Auto-Deploy
# -------------------------------------------------------------

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  tags = {
    Environment = var.environment
  }
}

# -------------------------------------------------------------
# 5. HTTP Proxy Integration to Internal ALB via VPC Link
# -------------------------------------------------------------

resource "aws_apigatewayv2_integration" "alb" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = var.alb_listener_arn
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.link.id
  payload_format_version = "1.0"
}

# -------------------------------------------------------------
# 6. Cognito JWT Authorizer
# -------------------------------------------------------------

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id           = aws_apigatewayv2_api.api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-jwt-authorizer"

  jwt_configuration {
    audience = [var.cognito_client_id]
    issuer   = "https://${var.cognito_user_pool_endpoint}"
  }
}

# -------------------------------------------------------------
# 7. Routes (Public Products, CORS Preflight, Protected Proxy)
# -------------------------------------------------------------

# Route 1: Public products catalog (No auth required)
resource "aws_apigatewayv2_route" "products" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /products"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

# Route 2: CORS Preflight (OPTIONS /{proxy+} - No auth, avoids 401 on preflight)
resource "aws_apigatewayv2_route" "options_proxy" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "OPTIONS /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

# Route 3: Authenticated Proxy for all other microservice calls
resource "aws_apigatewayv2_route" "any_proxy" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.alb.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
}
