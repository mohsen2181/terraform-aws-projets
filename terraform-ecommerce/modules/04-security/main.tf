# -------------------------------------------------------------
# Security & Configuration Management (SSM Parameter Store)
# -------------------------------------------------------------

resource "aws_ssm_parameter" "aws_region" {
  name  = "/${var.project_name}/${var.environment}/aws/region"
  type  = "String"
  value = var.aws_region

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "db_host" {
  name  = "/${var.project_name}/${var.environment}/db/host"
  type  = "String"
  value = var.db_host

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/${var.environment}/db/password"
  type  = "SecureString"
  value = var.db_password

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "sns_topic_arn" {
  name  = "/${var.project_name}/${var.environment}/sns/topic-arn"
  type  = "String"
  value = var.sns_topic_arn

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
