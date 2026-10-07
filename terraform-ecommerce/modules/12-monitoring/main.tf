# =============================================================
# Module 12: Observability, CloudWatch Dashboard & Alarms
# =============================================================

# -------------------------------------------------------------
# 1. SNS Alert Topic for Critical Alarms
# -------------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  name         = "${var.project_name}-alerts-${var.environment}"
  display_name = "eCommerce Critical CloudWatch Alarms"

  tags = {
    Name        = "${var.project_name}-alerts-${var.environment}"
    Environment = var.environment
  }
}

# Optional Email Subscription for Alarms
resource "aws_sns_topic_subscription" "email_alert" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# -------------------------------------------------------------
# 2. Critical CloudWatch Metric Alarms
# -------------------------------------------------------------

# Alarm 1: API Gateway High 5xx Server Errors
resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  alarm_name          = "${var.project_name}-api-high-5xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5xx"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Triggered when API Gateway encounters more than 5 server 5xx errors in 5 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    ApiId = var.api_gateway_id
  }

  tags = {
    Environment = var.environment
  }
}

# Alarm 2: High RDS CPU Utilization (> 85% for 10 min)
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "${var.project_name}-rds-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Triggered when RDS PostgreSQL CPU utilization exceeds 85% for 10 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }

  tags = {
    Environment = var.environment
  }
}

# Alarm 3: Order Processor Lambda Failures
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-order-processor-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Triggered when Order Processor Lambda encounters unhandled exceptions"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = {
    Environment = var.environment
  }
}

# -------------------------------------------------------------
# 3. Unified CloudWatch Executive Operational Dashboard
# -------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Header Text Widget
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# 🚀 **eCommerce Production Operations & Performance Dashboard**\nReal-time monitoring across Edge, API Gateway, Load Balancers, ECS Microservices, RDS PostgreSQL, SQS, and Lambda."
        }
      },

      # Section 1: API Gateway Requests & Latency
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiId", var.api_gateway_id, { stat = "Sum", label = "Request Count", color = "#1f77b4" }],
            [".", "4xx", ".", ".", { stat = "Sum", label = "4xx Client Errors", color = "#ff7f0e" }],
            [".", "5xx", ".", ".", { stat = "Sum", label = "5xx Server Errors", color = "#d62728" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "API Gateway: Traffic & Error Rates"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiId", var.api_gateway_id, { stat = "p50", label = "p50 Latency (ms)", color = "#2ca02c" }],
            [".", ".", ".", ".", { stat = "p95", label = "p95 Latency (ms)", color = "#ff7f0e" }],
            [".", ".", ".", ".", { stat = "p99", label = "p99 Latency (ms)", color = "#d62728" }],
            [".", "IntegrationLatency", ".", ".", { stat = "Average", label = "ALB Backend Integration Latency (ms)", color = "#9467bd" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "API Gateway: Latency Percentiles"
          period  = 300
        }
      },

      # Section 2: ECS Fargate Services CPU & Memory Utilization
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.project_name}-product-service", "ClusterName", var.ecs_cluster_name, { stat = "Average", label = "Product Service CPU (%)" }],
            [".", ".", "ServiceName", "${var.project_name}-cart-service", "ClusterName", var.ecs_cluster_name, { stat = "Average", label = "Cart Service CPU (%)" }],
            [".", ".", "ServiceName", "${var.project_name}-user-service", "ClusterName", var.ecs_cluster_name, { stat = "Average", label = "User Service CPU (%)" }],
            [".", ".", "ServiceName", "${var.project_name}-order-service", "ClusterName", var.ecs_cluster_name, { stat = "Average", label = "Order Service CPU (%)" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Microservices: CPU Utilization (%) [Scale-Out at 70%]"
          period  = 300
          yAxis = {
            left = { min = 0, max = 100 }
          }
          annotations = {
            horizontal = [
              { label = "Auto-Scaling Threshold", value = 70, fill = "after", color = "#d62728" }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${var.project_name}-product-service", "ClusterName", var.ecs_cluster_name, { stat = "Average", label = "Product Service Memory (%)" }],
            [".", ".", "ServiceName", "${var.project_name}-cart-service", "ClusterName", var.ecs_cluster_name, { stat = "Average", label = "Cart Service Memory (%)" }],
            [".", ".", "ServiceName", "${var.project_name}-user-service", "ClusterName", var.ecs_cluster_name, { stat = "Average", label = "User Service Memory (%)" }],
            [".", ".", "ServiceName", "${var.project_name}-order-service", "ClusterName", var.ecs_cluster_name, { stat = "Average", label = "Order Service Memory (%)" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Microservices: Memory Utilization (%) [Scale-Out at 80%]"
          period  = 300
          yAxis = {
            left = { min = 0, max = 100 }
          }
          annotations = {
            horizontal = [
              { label = "Memory Threshold", value = 80, fill = "after", color = "#d62728" }
            ]
          }
        }
      },

      # Section 3: RDS PostgreSQL Performance & Storage
      {
        type   = "metric"
        x      = 0
        y      = 14
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_identifier, { stat = "Average", label = "RDS CPU (%)", color = "#1f77b4" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS PostgreSQL: CPU Utilization (%)"
          period  = 300
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 14
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_instance_identifier, { stat = "Average", label = "DB Connections", color = "#2ca02c" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS: Active Client Connections"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 14
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.rds_instance_identifier, { stat = "Average", label = "Free Storage (Bytes)", color = "#9467bd" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS: Available Disk Space"
          period  = 300
        }
      },

      # Section 4: Event-Driven Order Processing (SQS & Lambda)
      {
        type   = "metric"
        x      = 0
        y      = 20
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.sqs_queue_name, { stat = "Average", label = "Pending Order Messages", color = "#ff7f0e" }],
            [".", "ApproximateNumberOfMessagesNotVisible", "QueueName", var.sqs_queue_name, { stat = "Average", label = "In-Flight Messages (Processing)", color = "#1f77b4" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "SQS: Order Shipping Queue Depth"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 20
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.lambda_function_name, { stat = "Sum", label = "Invocations", color = "#2ca02c" }],
            [".", "Errors", ".", ".", { stat = "Sum", label = "Errors", color = "#d62728" }],
            [".", "Duration", ".", ".", { stat = "Average", label = "Avg Duration (ms)", color = "#1f77b4", yAxis = "right" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda: Order Processor Invocations & Errors"
          period  = 300
        }
      }
    ]
  })
}
