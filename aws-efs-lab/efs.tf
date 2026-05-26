resource "aws_efs_file_system" "efs" {
  creation_token = "efs-lab"

  encrypted = true

  performance_mode = "generalPurpose"

  throughput_mode = "elastic"

  
  # Move files to Infrequent Access
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  # Move files from IA to Archive
  lifecycle_policy {
    transition_to_archive = "AFTER_90_DAYS"
  }

  # Return files to Standard when accessed
  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name = "efs-lab"
  }
}


resource "aws_efs_access_point" "app_ap" {
  file_system_id = aws_efs_file_system.efs.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/app"

    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name = "app-access-point"
  }
}


resource "aws_efs_mount_target" "mt" {
  count = 3

  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.subnets[count.index].id
  security_groups = [aws_security_group.efs_sg.id]
}
