data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_app_subnet_az1.id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  user_data = base64encode(templatefile("${path.module}/user-data.sh.tpl", {
    aws_region         = var.aws_region
    secret_arn         = aws_secretsmanager_secret.app.arn
    app_repo_url       = var.app_repo_url
    app_repo_branch    = var.app_repo_branch
    ebs_device         = "/dev/xvdf"
    data_mount         = "/data"
    app_install_dir    = "/opt/vuln-bank"
  }))

  user_data_replace_on_change = false

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = var.ebs_size_gb
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name        = "${var.environment}-${var.project_name}-app"
    DeployTarget = "vuln-bank"
  }

  depends_on = [
    aws_nat_gateway.nat,
    aws_secretsmanager_secret_version.app
  ]

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app.id
  port             = 80
}
