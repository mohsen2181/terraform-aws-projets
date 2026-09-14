resource "aws_instance" "nfs_server" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = "t3.micro"
  subnet_id              = module.onprem_vpc.private_subnet_id
  vpc_security_group_ids = [aws_security_group.nfs_server_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # 1. Create shared folders
    mkdir -p /media/data/images

    # 2. Seed test files
    for i in $(seq -w 1 20); do
      echo "This is migration test file $i" > /media/data/images/file-$i.txt
    done
    echo "hello from nfs server" > /media/data/test-nfs.txt

    # 3. Set full permissions
    chown -R nobody:nobody /media/data
    chmod -R 777 /media/data

    # 4. Configure exports
    echo "/media/data *(rw,sync,no_root_squash,no_subtree_check)" > /etc/exports

    # 5. Enable and start NFS services
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

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -e

    mkdir -p /mnt/data
    NFS_SERVER="${aws_instance.nfs_server.private_ip}"

    # Wait for NFS server port 2049 to be open and accepting connections
    echo "Waiting for NFS server ($NFS_SERVER:2049)..."
    while ! (echo > /dev/tcp/$NFS_SERVER/2049) >/dev/null 2>&1; do
      sleep 3
    done
    echo "NFS server is reachable on port 2049."

    # Retry mounting until successful
    until mount -t nfs4 -o defaults,_netdev "$NFS_SERVER:/media/data" /mnt/data; do
      echo "Mount attempt failed, retrying in 3s..."
      sleep 3
    done
    echo "NFS mounted successfully."

    # Persist in fstab
    echo "$NFS_SERVER:/media/data /mnt/data nfs4 defaults,_netdev 0 0" >> /etc/fstab

    # Create app server test file
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