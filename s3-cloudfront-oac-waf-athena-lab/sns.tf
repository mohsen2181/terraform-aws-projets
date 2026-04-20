############################################
# SNS Topic
############################################
resource "aws_sns_topic" "alerts" {
  name = "waf-security-alerts"
}

############################################
# Email subscription
############################################
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}