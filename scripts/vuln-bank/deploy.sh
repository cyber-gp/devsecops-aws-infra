#!/bin/bash
# Runs on EC2 via SSM Run Command. Pulls latest app code and rebuilds containers.
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/vuln-bank}"
AWS_REGION="${AWS_REGION:-us-east-2}"
SSM_DEPLOY_CONFIG="${SSM_DEPLOY_CONFIG:-/dev/vulnbank/deploy_config}"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-vulnbank}"
APP_REPO_BRANCH_OVERRIDE="${APP_REPO_BRANCH_OVERRIDE:-}"

export AWS_DEFAULT_REGION="$AWS_REGION"

if [ -f /aws/default/SSM_DEPLOY_CONFIG ]; then
  SSM_DEPLOY_CONFIG=$(cat /aws/default/SSM_DEPLOY_CONFIG)
fi

CONFIG_JSON=$(aws ssm get-parameter --name "$SSM_DEPLOY_CONFIG" --query Parameter.Value --output text)

config_string() {
  local key="$1"
  local value

  if ! value=$(echo "$CONFIG_JSON" | jq -er --arg key "$key" '.[$key] | select(type == "string" and length > 0)'); then
    echo "Deploy config $SSM_DEPLOY_CONFIG is missing required string field: $key" >&2
    exit 1
  fi

  printf '%s\n' "$value"
}

APP_DIR=$(config_string app_install_dir)
APP_REPO_URL=$(config_string app_repo_url)
APP_REPO_BRANCH=$(config_string app_repo_branch)
SECRET_ARN=$(config_string secret_arn)
AWS_REGION_CONFIG=$(echo "$CONFIG_JSON" | jq -r '.aws_region // empty')

if [ -n "$AWS_REGION_CONFIG" ]; then
  AWS_REGION="$AWS_REGION_CONFIG"
  export AWS_DEFAULT_REGION="$AWS_REGION"
fi

if [ -n "$APP_REPO_BRANCH_OVERRIDE" ]; then
  APP_REPO_BRANCH="$APP_REPO_BRANCH_OVERRIDE"
fi

mkdir -p "$(dirname "$APP_DIR")"
if [ ! -d "$APP_DIR/.git" ]; then
  rm -rf "$APP_DIR"
  git clone --branch "$APP_REPO_BRANCH" "$APP_REPO_URL" "$APP_DIR"
else
  cd "$APP_DIR"
  git fetch origin
  git checkout "$APP_REPO_BRANCH"
  git pull --ff-only origin "$APP_REPO_BRANCH"
fi

cd "$APP_DIR"

SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --query SecretString --output text)
DB_PASSWORD=$(echo "$SECRET_JSON" | jq -er '.DB_PASSWORD')
DEEPSEEK_API_KEY=$(echo "$SECRET_JSON" | jq -r '.DEEPSEEK_API_KEY // empty')

cat > "$APP_DIR/.env" <<ENVFILE
DB_NAME=vulnerable_bank
DB_USER=postgres
DB_PASSWORD=$DB_PASSWORD
POSTGRES_DB=vulnerable_bank
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$DB_PASSWORD
DB_HOST=db
DB_PORT=5432
DEEPSEEK_API_KEY=$DEEPSEEK_API_KEY
ENVFILE
chmod 600 "$APP_DIR/.env"

cat > "$APP_DIR/docker-compose.prod.yml" <<'COMPOSE'
services:
  web:
    ports:
      - "80:5000"
    volumes:
      - /data/vuln-bank/uploads:/app/static/uploads
  db:
    ports: []
    volumes:
      - /data/vuln-bank/volumes/postgres_data:/var/lib/postgresql/data
COMPOSE

export COMPOSE_FILE="docker-compose.yml:docker-compose.prod.yml"

docker compose -p "$COMPOSE_PROJECT_NAME" down || true
docker compose -p "$COMPOSE_PROJECT_NAME" build
docker compose -p "$COMPOSE_PROJECT_NAME" up -d
docker image prune -f

echo "Deploy finished."
