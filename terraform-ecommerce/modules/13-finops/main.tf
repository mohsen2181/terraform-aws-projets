# AWS Budget - Monthly Cost Cap ($25.00)
resource "aws_budgets_budget" "cost_budget" {
  name              = var.budget_name
  budget_type       = "COST"
  limit_amount      = var.budget_amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2026-01-01_00:00"

  # 1. Alert at 80% of ACTUAL spend ($20.00)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.notification_emails
  }

  # 2. Alert at 100% of FORECASTED spend ($25.00)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.notification_emails
  }
}

# CloudWatch Billing Alarm for Estimated Charges ($20.00)
resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  alarm_name          = "ecommerce-billing-alarm-monthly"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "21600" # 6 hours
  statistic           = "Maximum"
  threshold           = var.alarm_threshold
  alarm_description   = "Alarm triggered when estimated monthly AWS charges exceed threshold"

  dimensions = {
    Currency = "USD"
  }
}
