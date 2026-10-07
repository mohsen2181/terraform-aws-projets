# -------------------------------------------------------------
# 1. Target Groups for Microservices (Target Type: IP)
# -------------------------------------------------------------

resource "aws_lb_target_group" "product" {
  name        = "product-service-tg"
  port        = 8001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "product-service-tg"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "cart" {
  name        = "cart-service-tg"
  port        = 8002
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "cart-service-tg"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "user" {
  name        = "user-service-tg"
  port        = 8003
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "user-service-tg"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "order" {
  name        = "order-service-tg"
  port        = 8004
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "order-service-tg"
    Environment = var.environment
  }
}

# -------------------------------------------------------------
# 2. Internal Application Load Balancer
# -------------------------------------------------------------

resource "aws_lb" "internal" {
  name               = "${var.project_name}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.private_app_subnet_ids

  tags = {
    Name        = "${var.project_name}-internal-alb"
    Environment = var.environment
  }
}

# -------------------------------------------------------------
# 3. HTTP:80 Listener & Path-Based Routing Rules
# -------------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  # Default action forwards to product service
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.product.arn
  }
}

# Rule 1: /products* -> product-service-tg
resource "aws_lb_listener_rule" "product" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.product.arn
  }

  condition {
    path_pattern {
      values = ["/products*"]
    }
  }
}

# Rule 2: /cart* -> cart-service-tg
resource "aws_lb_listener_rule" "cart" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cart.arn
  }

  condition {
    path_pattern {
      values = ["/cart*"]
    }
  }
}

# Rule 3: /users* -> user-service-tg
resource "aws_lb_listener_rule" "user" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 3

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user.arn
  }

  condition {
    path_pattern {
      values = ["/users*"]
    }
  }
}

# Rule 4: /orders* -> order-service-tg
resource "aws_lb_listener_rule" "order" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 4

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.order.arn
  }

  condition {
    path_pattern {
      values = ["/orders*"]
    }
  }
}

# -------------------------------------------------------------
# 4. Systems Manager Parameters for Service URLs
# -------------------------------------------------------------

resource "aws_ssm_parameter" "user_service_url" {
  name  = "/${var.project_name}/${var.environment}/user-service-url"
  type  = "String"
  value = "http://${aws_lb.internal.dns_name}"

  tags = {
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "cart_service_url" {
  name  = "/${var.project_name}/${var.environment}/cart-service-url"
  type  = "String"
  value = "http://${aws_lb.internal.dns_name}"

  tags = {
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "product_service_url" {
  name  = "/${var.project_name}/${var.environment}/product-service-url"
  type  = "String"
  value = "http://${aws_lb.internal.dns_name}"

  tags = {
    Environment = var.environment
  }
}
