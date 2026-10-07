# -------------------------------------------------------------
# 1. DynamoDB Tables
# -------------------------------------------------------------

# Products Table
resource "aws_dynamodb_table" "products" {
  name         = "${var.project_name}-products"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "product_id"

  attribute {
    name = "product_id"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-products"
    Environment = var.environment
  }
}

# Cart Table
resource "aws_dynamodb_table" "cart" {
  name         = "${var.project_name}-cart"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-cart"
    Environment = var.environment
  }
}

# -------------------------------------------------------------
# 2. RDS PostgreSQL Database
# -------------------------------------------------------------

# DB Subnet Group across private DB subnets
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Subnet group for ${var.project_name} RDS PostgreSQL"
  subnet_ids  = var.private_db_subnet_ids

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier              = "ecommercedb-instance"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = var.db_instance_class
  allocated_storage       = var.allocated_storage
  storage_type            = "gp3"
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [var.rds_security_group_id]
  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 0

  tags = {
    Name        = "ecommercedb-instance"
    Environment = var.environment
  }
}
