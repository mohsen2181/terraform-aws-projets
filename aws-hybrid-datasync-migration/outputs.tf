output "onprem_vpc_id" {
  value = module.onprem_vpc.vpc_id
}

output "onprem_public_subnet_id" {
  value = module.onprem_vpc.public_subnet_id
}

output "onprem_private_subnet_id" {
  value = module.onprem_vpc.private_subnet_id
}

output "cloud_vpc_id" {
  value = module.cloud_vpc.vpc_id
}

output "cloud_public_subnet_id" {
  value = module.cloud_vpc.public_subnet_id
}

output "cloud_private_subnet_id" {
  value = module.cloud_vpc.private_subnet_id
}

output "nfs_server_private_ip" {
  value = aws_instance.nfs_server.private_ip
}

output "app_server_private_ip" {
  value = aws_instance.app_server.private_ip
}


output "datasync_agent_private_ip" {
  value = aws_instance.datasync_agent.private_ip
}


output "migration_bucket_name" {
  value = aws_s3_bucket.migration_bucket.bucket
}

output "migration_bucket_arn" {
  value = aws_s3_bucket.migration_bucket.arn
}

output "datasync_s3_role_arn" {
  value = aws_iam_role.datasync_s3_role.arn
}

output "datasync_task_arn" {
  value = aws_datasync_task.nfs_to_s3.arn
}