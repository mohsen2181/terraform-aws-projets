# -------------------------------------------------------------
# 1. ECS Cluster
# -------------------------------------------------------------

resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = var.environment
  }
}

# -------------------------------------------------------------
# 2. IAM Roles for ECS Tasks
# -------------------------------------------------------------

# ECS Task Execution Role (used by ECS agent to pull images and push logs)
resource "aws_iam_role" "execution_role" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "execution_role_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role (used by application code inside container)
resource "aws_iam_role" "task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

locals {
  task_policies = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSNSFullAccess",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  ]
}

resource "aws_iam_role_policy_attachment" "task_role_policies" {
  for_each   = toset(local.task_policies)
  role       = aws_iam_role.task_role.name
  policy_arn = each.value
}

# -------------------------------------------------------------
# 3. CloudWatch Log Groups
# -------------------------------------------------------------

locals {
  services = {
    "product-service" = { port = 8001, tg_arn = var.product_target_group_arn }
    "cart-service"    = { port = 8002, tg_arn = var.cart_target_group_arn }
    "user-service"    = { port = 8003, tg_arn = var.user_target_group_arn }
    "order-service"   = { port = 8004, tg_arn = var.order_target_group_arn }
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  for_each          = local.services
  name              = "/ecs/${each.key}"
  retention_in_days = 7

  tags = {
    Service     = each.key
    Environment = var.environment
  }
}

# -------------------------------------------------------------
# 4. ECS Task Definitions & Fargate Services
# -------------------------------------------------------------

resource "aws_ecs_task_definition" "tasks" {
  for_each                 = local.services
  family                   = "${var.project_name}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = "${var.ecr_repository_urls[each.key]}:latest"
      essential = true
      portMappings = [
        {
          containerPort = each.value.port
          hostPort      = each.value.port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "ENVIRONMENT", value = var.environment },
        { name = "AWS_REGION", value = var.aws_region }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.logs[each.key].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = {
    Name        = "${var.project_name}-${each.key}"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "services" {
  for_each        = local.services
  name            = "${var.project_name}-${each.key}"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.tasks[each.key].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_app_subnet_ids
    security_groups  = [var.ecs_tasks_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = each.value.tg_arn
    container_name   = each.key
    container_port   = each.value.port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Name        = "${var.project_name}-${each.key}"
    Environment = var.environment
  }
}

# -------------------------------------------------------------
# 5. Application Auto Scaling for ECS Services
# -------------------------------------------------------------

# Scalable Target: Registers each ECS Service with Application Auto Scaling
resource "aws_appautoscaling_target" "ecs_target" {
  for_each           = local.services
  max_capacity       = var.max_capacity
  min_capacity       = 0
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.services[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Target Tracking Policy: CPU Utilization (Target: 70%)
resource "aws_appautoscaling_policy" "cpu_policy" {
  for_each           = local.services
  name               = "${var.project_name}-${each.key}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_target_utilization
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Target Tracking Policy: Memory Utilization (Target: 80%)
resource "aws_appautoscaling_policy" "memory_policy" {
  for_each           = local.services
  name               = "${var.project_name}-${each.key}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.memory_target_utilization
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# -------------------------------------------------------------
# 6. Scheduled Scaling (FinOps: Night-Mode Scale to 0)
# -------------------------------------------------------------

# Night-Mode: Scale to 0 tasks every day at 22:00 UTC (10:00 PM)
resource "aws_appautoscaling_scheduled_action" "scale_down_night" {
  for_each           = var.enable_scheduled_scaling ? local.services : {}
  name               = "${var.project_name}-${each.key}-night-scale-down"
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  schedule           = var.scale_down_cron

  scalable_target_action {
    min_capacity = 0
    max_capacity = 0
  }
}

# Morning Wakeup: Scale back to min_capacity (1) every day at 08:00 UTC
resource "aws_appautoscaling_scheduled_action" "scale_up_morning" {
  for_each           = var.enable_scheduled_scaling ? local.services : {}
  name               = "${var.project_name}-${each.key}-morning-scale-up"
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  schedule           = var.scale_up_cron

  scalable_target_action {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }
}
