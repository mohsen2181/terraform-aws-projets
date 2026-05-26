data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "ec2" {
  count         = 3
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  subnet_id              = aws_subnet.subnets[count.index].id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

user_data = templatefile("${path.module}/user_data.sh.tpl", {
  efs_id = aws_efs_file_system.efs.id
  ap_id  = aws_efs_access_point.app_ap.id
  region = var.region
  efs_dns = "${aws_efs_file_system.efs.id}.efs.eu-west-3.amazonaws.com"
})
  tags = {
    Name = "ec2-${count.index + 1}"
  }
}
