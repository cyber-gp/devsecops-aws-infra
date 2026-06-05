#!/bin/bash
# Runs on EC2 via SSM Run Command. Pulls latest app code and rebuilds containers.
set -euxo pipefail

APP_DIR="${APP_DIR:-/opt/vuln-bank}"
AWS_REGION="${AWS_REGION:-us-east-2}"
SSM_DEPLOY_CONFIG="${SSM_DEPLOY_CONFIG:-/dev/vulnbank/deploy_config}"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-vulnbank}"

export AWS_DEFAULT_REGION="$AWS_REGION"

if [ -f /aws/default/SSM_DEPLOY_CONFIG ]; then
  SSM_DEPLOY_CONFIG=$(cat /aws/default/SSM_DEPLOY_CONFIG)
fi

CONFIG_JSON=$(aws ssm get-parameter --name "$SSM_DEPLOY_CONFIG" --query Parameter.Value --output text)
APP_DIR=$(echo "$CONFIG_JSON" | jq -r '.app_install_dir')
APP_REPO_URL=$(echo "$CONFIG_JSON" | jq -r '.app_repo_url')
APP_REPO_BRANCH=$(echo "$CONFIG_JSON" | jq -r '.app_repo_branch')
SECRET_ARN=$(echo "$CONFIG_JSON" | jq -r '.secret_arn')

cd "$APP_DIR"

if [ ! -d .git ]; then
  git clone --branch "$APP_REPO_BRANCH" "$APP_REPO_URL" "$APP_DIR"
else
  git fetch origin
  git checkout "$APP_REPO_BRANCH"
  git pull origin "$APP_REPO_BRANCH"
fi

SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --query SecretString --output text)
DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.DB_PASSWORD')
DEEPSEEK_API_KEY=$(echo "$SECRET_JSON" | jq -r '.DEEPSEEK_API_KEY // empty')

cat > "$APP_DIR/.env" <<ENVFILE
DB_NAME=vulnerable_bank
DB_USER=postgres
DB_PASSWORD=$DB_PASSWORD
DB_HOST=db
DB_PORT=5432
DEEPSEEK_API_KEY=$DEEPSEEK_API_KEY
ENVFILE

if [ ! -f "$APP_DIR/docker-compose.prod.yml" ]; then
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
fi

export COMPOSE_FILE="docker-compose.yml:docker-compose.prod.yml"

docker compose -p "$COMPOSE_PROJECT_NAME" down || true
docker compose -p "$COMPOSE_PROJECT_NAME" build
docker compose -p "$COMPOSE_PROJECT_NAME" up -d
docker image prune -f

echo "Deploy finished."
