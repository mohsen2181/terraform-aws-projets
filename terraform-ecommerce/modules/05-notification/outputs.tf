output "sns_topic_arn" {
  description = "Order events SNS topic ARN"
  value       = aws_sns_topic.order_events.arn
}

output "sns_topic_name" {
  description = "Order events SNS topic Name"
  value       = aws_sns_topic.order_events.name
}

output "sqs_queue_arn" {
  description = "Order shipping SQS queue ARN"
  value       = aws_sqs_queue.order_shipping.arn
}

output "sqs_queue_url" {
  description = "Order shipping SQS queue URL"
  value       = aws_sqs_queue.order_shipping.url
}

output "sqs_queue_name" {
  description = "Order shipping SQS queue Name"
  value       = aws_sqs_queue.order_shipping.name
}
