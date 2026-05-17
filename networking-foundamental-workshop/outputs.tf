output "vpc_id" {
  value = aws_vpc.vpc_a.id
}

output "public_subnet_az1_id" {
  value = aws_subnet.public_az1.id
}

output "private_subnet_az1_id" {
  value = aws_subnet.private_az1.id
}

output "public_subnet_az2_id" {
  value = aws_subnet.public_az2.id
}

output "private_subnet_az3_id" {
  value = aws_subnet.private_az3.id
}

output "public_ec2_instance_id" {
  value = aws_instance.public_az2.id
}


output "public_ec2_public_ip" {
  value = aws_instance.public_az2.public_ip
}

output "public_ec2_private_ip" {
  value = aws_instance.public_az2.private_ip
}

output "private_ec2_private_ip" {
  value = aws_instance.private_az1.private_ip
}

output "private_ec2_instance_id" {
  value = aws_instance.private_az1.id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.gateway_endpoint_bucket.bucket
}

output "kms_endpoint_id" {
  value = aws_vpc_endpoint.kms.id
}

output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}
