# Sensitive values (db_password, deepseek_api_key) are supplied via Terraform Cloud
# workspace variables — never commit them to tfvars or this repository.

locals {
  app_secret_payload = {
    DB_NAME           = var.db_name
    DB_USER           = var.db_user
    DB_PASSWORD       = var.db_password
    DB_HOST           = var.db_host
    DB_PORT           = var.db_port
    DEEPSEEK_API_KEY  = var.deepseek_api_key
    POSTGRES_DB       = var.db_name
    POSTGRES_USER     = var.db_user
    POSTGRES_PASSWORD = var.db_password
  }
}

resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.environment}-${var.project_name}-app-secrets"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.environment}-${var.project_name}-app-secrets"
  }
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id     = aws_secretsmanager_secret.app.id
  secret_string = jsonencode(local.app_secret_payload)
}
