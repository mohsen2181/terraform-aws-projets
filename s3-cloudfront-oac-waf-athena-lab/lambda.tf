############################################
# IAM Role for Lambda
############################################
resource "aws_iam_role" "lambda_role" {
  name = "waf-auto-block-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

############################################
# IAM Policy for WAF + Logs + S3 + SNS + DDB
############################################
resource "aws_iam_role_policy" "lambda_policy" {
  name = "waf-auto-block-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      {
        Effect = "Allow"
        Action = [
          "wafv2:GetIPSet",
          "wafv2:UpdateIPSet"
        ]
        Resource = "*"
      },

      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.logs.arn}/*"
      },

      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },

      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.alerts.arn
      },

      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = aws_dynamodb_table.blocked_ips.arn
      }
    ]
  })
}

############################################
# Package Lambda
############################################
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/index.py"
  output_path = "${path.module}/lambda.zip"
}

############################################
# Lambda Function
############################################
resource "aws_lambda_function" "auto_block" {
  function_name = "auto-block-ip"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.11"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      IP_SET_ID   = aws_wafv2_ip_set.blocked_ips.id
      IP_SET_NAME = aws_wafv2_ip_set.blocked_ips.name
      REGION      = "us-east-1"

      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
      DDB_TABLE     = aws_dynamodb_table.blocked_ips.name
    }
  }
}

############################################
# Allow S3 to invoke Lambda
############################################
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_block.function_name
  principal     = "s3.amazonaws.com"

  source_arn = aws_s3_bucket.logs.arn
}