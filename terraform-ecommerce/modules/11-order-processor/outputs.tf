output "lambda_function_name" {
  description = "Name of the order processor Lambda function"
  value       = aws_lambda_function.order_processor.function_name
}

output "lambda_function_arn" {
  description = "ARN of the order processor Lambda function"
  value       = aws_lambda_function.order_processor.arn
}

output "lambda_security_group_id" {
  description = "Security group ID of the order processor Lambda function"
  value       = aws_security_group.lambda_sg.id
}
