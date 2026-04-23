resource "aws_db_subnet_group" "db_subnet" {
  subnet_ids = [
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]
}

resource "aws_db_instance" "postgres" {
  identifier        = "secure-db"
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_user
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name

  skip_final_snapshot = true
  publicly_accessible = true
}
