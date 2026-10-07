# -------------------------------------------------------------
# Notification & Event-Driven Messaging (SNS & SQS)
# -------------------------------------------------------------

# SNS Topic for order events
resource "aws_sns_topic" "order_events" {
  name         = "${var.project_name}-order-events"
  display_name = "eCommerce Order Events"

  tags = {
    Name        = "${var.project_name}-order-events"
    Environment = var.environment
  }
}

# SQS Queue for order shipping
resource "aws_sqs_queue" "order_shipping" {
  name = "${var.project_name}-order-shipping"

  tags = {
    Name        = "${var.project_name}-order-shipping"
    Environment = var.environment
  }
}

# Subscribe SQS to SNS Topic
resource "aws_sns_topic_subscription" "sqs_target" {
  topic_arn = aws_sns_topic.order_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order_shipping.arn
}

# Allow SNS Topic to publish into SQS Queue
resource "aws_sqs_queue_policy" "allow_sns" {
  queue_url = aws_sqs_queue.order_shipping.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.order_shipping.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.order_events.arn
          }
        }
      }
    ]
  })
}
