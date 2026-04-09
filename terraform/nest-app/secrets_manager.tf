# Database credentials from Secrets Manager
data "aws_secretsmanager_secret_version" "secrets" {
  secret_id = var.secret_name
}

# Parse secret JSON for easier reference
locals {
  secrets = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)
}