output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = aws_subnet.subnets[*].id
}

output "availability_zones" {
  value = data.aws_availability_zones.azs.names
}

output "efs_file_system_id" {
  description = "EFS File System ID"
  value       = aws_efs_file_system.efs.id
}

output "efs_arn" {
  description = "EFS ARN"
  value       = aws_efs_file_system.efs.arn
}


output "efs_access_point_id" {
  description = "EFS Access Point ID"
  value       = aws_efs_access_point.app_ap.id
}

output "efs_access_point_arn" {
  description = "EFS Access Point ARN"
  value       = aws_efs_access_point.app_ap.arn
}


output "efs_mount_target_ids" {
  description = "EFS Mount Target IDs (one per subnet/AZ)"
  value       = aws_efs_mount_target.mt[*].id
}


output "efs_throughput_mode" {
  description = "Throughput mode used by EFS"
  value       = aws_efs_file_system.efs.throughput_mode
}

output "efs_performance_mode" {
  description = "Performance mode used by EFS"
  value       = aws_efs_file_system.efs.performance_mode
}


output "efs_lifecycle_policy" {
  description = "EFS lifecycle policy configuration"
  value       = aws_efs_file_system.efs.lifecycle_policy
}

output "ec2_public_ips" {
  description = "Public IPs of EC2 instances"
  value       = aws_instance.ec2[*].public_ip
}

output "ssm_commands" {
  value = [
    for instance in aws_instance.ec2 :
    "aws ssm start-session --target ${instance.id} --region ${var.region}"
  ]
}

output "instance_azs" {
  description = "EC2 Availability Zones"
  value       = aws_instance.ec2[*].availability_zone
}

output "instance_ids" {
  description = "EC2 instance IDs"
  value       = aws_instance.ec2[*].id
}
