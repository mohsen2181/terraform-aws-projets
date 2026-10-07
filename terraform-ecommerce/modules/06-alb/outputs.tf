output "alb_arn" {
  description = "Internal ALB ARN"
  value       = aws_lb.internal.arn
}

output "alb_dns_name" {
  description = "Internal ALB DNS name"
  value       = aws_lb.internal.dns_name
}

output "listener_arn" {
  description = "Internal ALB HTTP listener ARN"
  value       = aws_lb_listener.http.arn
}

output "product_target_group_arn" {
  description = "Product service target group ARN"
  value       = aws_lb_target_group.product.arn
}

output "cart_target_group_arn" {
  description = "Cart service target group ARN"
  value       = aws_lb_target_group.cart.arn
}

output "user_target_group_arn" {
  description = "User service target group ARN"
  value       = aws_lb_target_group.user.arn
}

output "order_target_group_arn" {
  description = "Order service target group ARN"
  value       = aws_lb_target_group.order.arn
}

output "alb_arn_suffix" {
  description = "Internal ALB ARN suffix for CloudWatch metrics"
  value       = aws_lb.internal.arn_suffix
}
