# =============================================================
# Module 11: Asynchronous SQS Order Processor Lambda
# =============================================================

# -------------------------------------------------------------
# 1. Security Group for Lambda Function
# -------------------------------------------------------------
resource "aws_security_group" "lambda_sg" {
  name        = "${var.project_name}-order-processor-sg-${var.environment}"
  description = "Security group for order processor Lambda function"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound traffic to RDS and VPC endpoints"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-order-processor-sg-${var.environment}"
    Environment = var.environment
  }
}

# Allow Lambda security group to access RDS PostgreSQL on port 5432
resource "aws_security_group_rule" "rds_ingress_lambda" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_sg.id
  security_group_id        = var.rds_security_group_id
  description              = "Allow PostgreSQL access from Order Processor Lambda"
}

# -------------------------------------------------------------
# 2. IAM Role & Policies for Lambda
# -------------------------------------------------------------
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-order-processor-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-order-processor-role-${var.environment}"
    Environment = var.environment
  }
}

# AWS Managed policy for VPC execution (ENI creation/deletion)
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# AWS Managed policy for X-Ray tracing
resource "aws_iam_role_policy_attachment" "lambda_xray_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Scoped policy for consuming SQS queue messages
resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "${var.project_name}-order-processor-sqs-policy-${var.environment}"
  description = "Allows Lambda to consume messages from order-shipping SQS queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_queue_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}

# -------------------------------------------------------------
# 3. Lambda Deployment Package
# -------------------------------------------------------------
locals {
  lambda_zip_path = "${path.root}/../../backend/order-processor/order_processor.zip"
}

# -------------------------------------------------------------
# 4. Lambda Function Definition
# -------------------------------------------------------------
resource "aws_lambda_function" "order_processor" {
  function_name    = "${var.project_name}-order-processor-${var.environment}"
  description      = "Asynchronously processes eCommerce order events from SQS and updates RDS"
  filename         = local.lambda_zip_path
  source_code_hash = filebase64sha256(local.lambda_zip_path)
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = var.private_app_subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DB_HOST     = var.db_host
      DB_NAME     = "ecommercedb"
      DB_USER     = "postgres"
      DB_PASSWORD = var.db_password
      DB_PORT     = "5432"
    }
  }

  tags = {
    Name        = "${var.project_name}-order-processor-${var.environment}"
    Environment = var.environment
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.order_processor.function_name}"
  retention_in_days = 7

  tags = {
    Environment = var.environment
  }
}

# -------------------------------------------------------------
# 5. SQS Event Source Mapping
# -------------------------------------------------------------
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.order_processor.arn
  batch_size       = 5
  enabled          = true
}
