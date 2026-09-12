# DB Subnet Group spanning the two DB private subnets across both AZs (Required for Multi-AZ)
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-mysql-subnet-group"
  subnet_ids = [aws_subnet.db_1.id, aws_subnet.db_2.id]

  tags = {
    Name = "MySQL DB Subnet Group"
  }
}

# RDS MySQL Multi-AZ Instance
resource "aws_db_instance" "mysql_db" {
  identifier             = "mysql-database"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  max_allocated_storage  = 50
  storage_type           = "gp3"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  
  # Multi-AZ enabled: AWS automatically provisions & maintains a synchronous standby replica in the second AZ
  multi_az                = true
  backup_retention_period = 7
  skip_final_snapshot     = true
  publicly_accessible     = false
  deletion_protection     = false

  tags = {
    Name = "mysql-multiaz-db"
  }
}
