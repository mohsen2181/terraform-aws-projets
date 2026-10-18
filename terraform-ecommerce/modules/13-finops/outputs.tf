output "budget_id" {
  description = "The ID of the AWS Budget"
  value       = aws_budgets_budget.cost_budget.id
}

output "billing_alarm_arn" {
  description = "The ARN of the CloudWatch billing alarm"
  value       = aws_cloudwatch_metric_alarm.billing_alarm.arn
}
