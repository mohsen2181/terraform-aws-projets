data "aws_availability_zones" "available" {}

module "onprem_vpc" {
  source = "./modules/vpc"

  name                = "vpc-onprem-simulated"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  availability_zone   = data.aws_availability_zones.available.names[0]
}

module "cloud_vpc" {
  source = "./modules/vpc"

  name                = "vpc-cloud"
  vpc_cidr            = "172.16.0.0/16"
  public_subnet_cidr  = "172.16.1.0/24"
  private_subnet_cidr = "172.16.2.0/24"
  availability_zone   = data.aws_availability_zones.available.names[0]
}


resource "aws_vpc_peering_connection" "onprem_to_cloud" {
  vpc_id      = module.onprem_vpc.vpc_id
  peer_vpc_id = module.cloud_vpc.vpc_id
  auto_accept = true

  tags = {
    Name = "onprem-to-cloud-peering"
  }
}

resource "aws_route" "onprem_private_to_cloud" {
  route_table_id            = module.onprem_vpc.private_route_table_id
  destination_cidr_block    = module.cloud_vpc.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.onprem_to_cloud.id
}

resource "aws_route" "cloud_private_to_onprem" {
  route_table_id            = module.cloud_vpc.private_route_table_id
  destination_cidr_block    = module.onprem_vpc.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.onprem_to_cloud.id
}

#Optional, but useful for testing from public subnets:
resource "aws_route" "onprem_public_to_cloud" {
  route_table_id            = module.onprem_vpc.public_route_table_id
  destination_cidr_block    = module.cloud_vpc.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.onprem_to_cloud.id
}

resource "aws_route" "cloud_public_to_onprem" {
  route_table_id            = module.cloud_vpc.public_route_table_id
  destination_cidr_block    = module.onprem_vpc.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.onprem_to_cloud.id
}


resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "migration_bucket" {
  bucket        = "migration-lab-datasync-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "migration-lab-datasync-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "migration_bucket" {
  bucket = aws_s3_bucket.migration_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_server_side_encryption_configuration" "migration_bucket" {
  bucket = aws_s3_bucket.migration_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_versioning" "migration_bucket" {
  bucket = aws_s3_bucket.migration_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_datasync_agent" "datasync_agent" {
  ip_address = aws_instance.datasync_agent.public_ip
  name       = "onprem-datasync-agent"

  depends_on = [
    aws_instance.datasync_agent
  ]
}


resource "aws_datasync_location_nfs" "nfs_source" {
  server_hostname = aws_instance.nfs_server.private_ip
  subdirectory    = "/media/data"

  on_prem_config {
    agent_arns = [
      aws_datasync_agent.datasync_agent.arn
    ]
  }

  mount_options {
    version = "NFS4_1"
  }
}


resource "aws_datasync_location_s3" "s3_destination" {
  s3_bucket_arn = aws_s3_bucket.migration_bucket.arn
  subdirectory  = "/migration-output"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3_role.arn
  }
}

resource "aws_datasync_task" "nfs_to_s3" {
  name = "nfs-to-s3-migration"

  source_location_arn      = aws_datasync_location_nfs.nfs_source.arn
  destination_location_arn = aws_datasync_location_s3.s3_destination.arn

  options {
    verify_mode            = "ONLY_FILES_TRANSFERRED"
    overwrite_mode         = "ALWAYS"
    transfer_mode          = "CHANGED"
    preserve_deleted_files = "PRESERVE"
  }
}
