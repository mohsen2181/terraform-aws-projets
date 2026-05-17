locals {
  project_name = "networking-fundamental-workshop"

  common_tags = {
    Project     = local.project_name
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Region      = var.aws_region
  }

  az1 = data.aws_availability_zones.available.names[0]
  az2 = data.aws_availability_zones.available.names[1]
  az3 = data.aws_availability_zones.available.names[2]
}
