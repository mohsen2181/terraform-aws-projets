output "cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.cluster.id
}

output "cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.cluster.name
}

output "cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.cluster.arn
}

output "service_names" {
  description = "Names of the deployed ECS services"
  value       = [for s in aws_ecs_service.services : s.name]
}

output "task_execution_role_arn" {
  description = "ECS Task Execution IAM Role ARN"
  value       = aws_iam_role.execution_role.arn
}

output "task_role_arn" {
  description = "ECS Task IAM Role ARN"
  value       = aws_iam_role.task_role.arn
}
