output "aws_region_param_name" {
  description = "SSM Parameter name for AWS Region"
  value       = aws_ssm_parameter.aws_region.name
}

output "db_host_param_name" {
  description = "SSM Parameter name for Database Host"
  value       = aws_ssm_parameter.db_host.name
}

output "db_password_param_name" {
  description = "SSM Parameter name for Database Password"
  value       = aws_ssm_parameter.db_password.name
}

output "sns_topic_arn_param_name" {
  description = "SSM Parameter name for SNS Topic ARN"
  value       = aws_ssm_parameter.sns_topic_arn.name
}
