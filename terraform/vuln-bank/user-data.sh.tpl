#!/bin/bash
set -euxo pipefail

AWS_REGION="${aws_region}"
SECRET_ARN="${secret_arn}"
APP_REPO_URL="${app_repo_url}"
APP_REPO_BRANCH="${app_repo_branch}"
EBS_DEVICE="${ebs_device}"
DATA_MOUNT="${data_mount}"
APP_DIR="${app_install_dir}"
COMPOSE_PROJECT_NAME="vulnbank"

export AWS_DEFAULT_REGION="$AWS_REGION"

# ---------------------------------------------------------------------------
# Packages: Docker, git, AWS CLI
# ---------------------------------------------------------------------------
dnf update -y
dnf install -y docker git awscli jq

systemctl enable --now docker
usermod -aG docker ec2-user || true

# Docker Compose v2 plugin
mkdir -p /usr/local/lib/docker/cli-plugins
COMPOSE_VERSION="v2.24.5"
curl -fsSL "https://github.com/docker/compose/releases/download/$${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

systemctl enable --now amazon-ssm-agent

# ---------------------------------------------------------------------------
# Mount persistent EBS volume
# ---------------------------------------------------------------------------
mkdir -p "$DATA_MOUNT"

if ! blkid "$EBS_DEVICE"; then
  # Wait for volume attachment (up to 3 minutes)
  for i in $(seq 1 36); do
    if [ -b "$EBS_DEVICE" ]; then
      break
    fi
    sleep 5
  done
  if [ -b "$EBS_DEVICE" ]; then
    mkfs -t xfs "$EBS_DEVICE"
  fi
fi

if [ -b "$EBS_DEVICE" ]; then
  UUID=$(blkid -s UUID -o value "$EBS_DEVICE" || true)
  if [ -n "$UUID" ] && ! grep -q "$UUID" /etc/fstab; then
    echo "UUID=$UUID $DATA_MOUNT xfs defaults,nofail 0 2" >> /etc/fstab
  fi
  mount -a || mount "$EBS_DEVICE" "$DATA_MOUNT"
fi

mkdir -p "$DATA_MOUNT/docker" "$DATA_MOUNT/vuln-bank/volumes/postgres_data" "$DATA_MOUNT/vuln-bank/uploads"
chmod 777 "$DATA_MOUNT/vuln-bank/uploads"

# Docker data root on EBS (optional persistence for images)
if [ -d "$DATA_MOUNT/docker" ]; then
  mkdir -p /etc/docker
  echo "{\"data-root\": \"$DATA_MOUNT/docker\"}" > /etc/docker/daemon.json
  systemctl restart docker
fi

# ---------------------------------------------------------------------------
# Clone application from GitHub
# ---------------------------------------------------------------------------
mkdir -p "$(dirname "$APP_DIR")"
if [ ! -d "$APP_DIR/.git" ]; then
  git clone --branch "$APP_REPO_BRANCH" "$APP_REPO_URL" "$APP_DIR"
else
  cd "$APP_DIR"
  git fetch origin
  git checkout "$APP_REPO_BRANCH"
  git pull origin "$APP_REPO_BRANCH"
fi

cd "$APP_DIR"

# ---------------------------------------------------------------------------
# Write .env from Secrets Manager
# ---------------------------------------------------------------------------
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --query SecretString --output text)
DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.DB_PASSWORD')
POSTGRES_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.POSTGRES_PASSWORD')
DEEPSEEK_API_KEY=$(echo "$SECRET_JSON" | jq -r '.DEEPSEEK_API_KEY // empty')

cat > "$APP_DIR/.env" <<ENVFILE
DB_NAME=vulnerable_bank
DB_USER=postgres
DB_PASSWORD=$DB_PASSWORD
DB_HOST=db
DB_PORT=5432
DEEPSEEK_API_KEY=$DEEPSEEK_API_KEY
ENVFILE

# Production compose override: no public Postgres port, persist volumes on EBS
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

# Ensure start.sh exists (some branches use python app.py directly in Dockerfile)
if [ ! -f "$APP_DIR/start.sh" ]; then
  cat > "$APP_DIR/start.sh" <<'START'
#!/bin/sh
set -eu
DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-vulnerable_bank}"
echo "Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT}..."
until pg_isready -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" >/dev/null 2>&1; do
  sleep 2
done
echo "Starting Flask dev server (debug mode)..."
exec python app.py
START
  chmod +x "$APP_DIR/start.sh"
fi

docker compose -p "$COMPOSE_PROJECT_NAME" build
docker compose -p "$COMPOSE_PROJECT_NAME" up -d

echo "Bootstrap complete."
