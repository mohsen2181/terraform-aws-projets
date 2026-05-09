resource "aws_instance" "nfs_server" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = "t3.micro"
  subnet_id              = module.onprem_vpc.private_subnet_id
  vpc_security_group_ids = [aws_security_group.nfs_server_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nfs-utils

    mkdir -p /media/data/images

    for i in $(seq -w 1 20); do
      echo "This is migration test file $i" > /media/data/images/file-$i.txt
    done

    echo "hello from nfs server" > /media/data/test-nfs.txt

    chown -R nobody:nobody /media/data
    chmod -R 777 /media/data

    echo "/media/data *(rw,sync,no_root_squash)" > /etc/exports

    systemctl enable --now rpcbind
    systemctl enable --now nfs-server

    exportfs -rav
  EOF

  tags = {
    Name = "onprem-nfs-server"
  }
}


resource "aws_instance" "app_server" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = "t3.micro"
  subnet_id              = module.onprem_vpc.private_subnet_id
  vpc_security_group_ids = [aws_security_group.app_server_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nfs-utils

    mkdir -p /mnt/data

    echo "${aws_instance.nfs_server.private_ip}:/media/data /mnt/data nfs defaults,_netdev 0 0" >> /etc/fstab

    mount -a

    echo "App server test file created at $(date)" > /mnt/data/app-server-test.txt
  EOF

  depends_on = [
    aws_instance.nfs_server
  ]

  tags = {
    Name = "onprem-app-server"
  }
}


resource "aws_instance" "datasync_agent" {
  ami                    = data.aws_ami.datasync_agent.id
  instance_type          = "t3.medium"
  subnet_id              = module.onprem_vpc.public_subnet_id
  vpc_security_group_ids = [aws_security_group.datasync_agent_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 80
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "onprem-datasync-agent"
  }
}