resource "random_password" "db_password" {
  length  = 24
  special = true
}

resource "aws_secretsmanager_secret" "app" {
  name = "${var.environment}-${var.project_name}-app-secrets"
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    DB_NAME           = "vulnerable_bank"
    DB_USER           = "postgres"
    DB_PASSWORD       = random_password.db_password.result
    DB_HOST           = "db"
    DB_PORT           = "5432"
    DEEPSEEK_API_KEY  = var.deepseek_api_key
    POSTGRES_DB       = "vulnerable_bank"
    POSTGRES_USER     = "postgres"
    POSTGRES_PASSWORD = random_password.db_password.result
  })
}
