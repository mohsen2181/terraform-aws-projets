variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "ecommerce"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "private_app_subnet_ids" {
  description = "Private app subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_tasks_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "product_target_group_arn" {
  description = "Target group ARN for product service"
  type        = string
}

variable "cart_target_group_arn" {
  description = "Target group ARN for cart service"
  type        = string
}

variable "user_target_group_arn" {
  description = "Target group ARN for user service"
  type        = string
}

variable "order_target_group_arn" {
  description = "Target group ARN for order service"
  type        = string
}

variable "ecr_repository_urls" {
  description = "Map of microservice names to ECR repository URLs"
  type        = map(string)
}

variable "min_capacity" {
  description = "Minimum number of tasks during active hours"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks during traffic spikes"
  type        = number
  default     = 4
}

variable "cpu_target_utilization" {
  description = "Target average CPU utilization percentage for auto-scaling"
  type        = number
  default     = 70
}

variable "memory_target_utilization" {
  description = "Target average memory utilization percentage for auto-scaling"
  type        = number
  default     = 80
}

variable "enable_scheduled_scaling" {
  description = "Enable scheduled scale down to 0 at night and scale up in the morning"
  type        = bool
  default     = true
}

variable "scale_down_cron" {
  description = "Cron schedule to scale ECS tasks to 0 (default: 22:00 UTC)"
  type        = string
  default     = "cron(0 22 * * ? *)"
}

variable "scale_up_cron" {
  description = "Cron schedule to scale ECS tasks back to min_capacity (default: 08:00 UTC)"
  type        = string
  default     = "cron(0 8 * * ? *)"
}
