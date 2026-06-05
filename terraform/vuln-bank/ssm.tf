resource "aws_ssm_parameter" "ec2_instance_id" {
  name  = "/${var.environment}/${var.project_name}/ec2_instance_id"
  type  = "String"
  value = aws_instance.app.id

  tags = {
    Name = "${var.environment}-${var.project_name}-instance-id"
  }
}

resource "aws_ssm_parameter" "deploy_config" {
  name = "/${var.environment}/${var.project_name}/deploy_config"
  type = "String"
  value = jsonencode({
    app_install_dir = "/opt/vuln-bank"
    app_repo_url    = var.app_repo_url
    app_repo_branch = var.app_repo_branch
    secret_arn      = aws_secretsmanager_secret.app.arn
    aws_region      = var.aws_region
    website_url     = "https://${var.record_name}.${var.domain_name}"
  })
}
