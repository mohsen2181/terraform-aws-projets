resource "aws_security_group" "nfs_server_sg" {
  name        = "nfs-server-sg"
  description = "Allow NFS access from App Server and DataSync Agent"
  vpc_id      = module.onprem_vpc.vpc_id

  ingress {
    description = "NFS from OnPrem VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [module.onprem_vpc.vpc_cidr]
  }

  ingress {
    description = "SSH from OnPrem public subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    description = "Allow outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nfs-server-sg"
  }
}

resource "aws_security_group" "app_server_sg" {
  name        = "app-server-sg"
  description = "Application server security group"
  vpc_id      = module.onprem_vpc.vpc_id

  ingress {
    description = "SSH from OnPrem public subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    description = "Allow outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-server-sg"
  }
}


resource "aws_security_group" "datasync_agent_sg" {
  name        = "datasync-agent-sg"
  description = "DataSync Agent security group"
  vpc_id      = module.onprem_vpc.vpc_id

  ingress {
    description = "SSH from OnPrem public subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  ingress {
    description = "Agent activation and management HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.onprem_vpc.vpc_cidr]
  }

  ingress {
    description = "Temporary DataSync activation from my IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["176.147.243.147/32"]
  }

  egress {
    description = "Allow outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "datasync-agent-sg"
  }
}
