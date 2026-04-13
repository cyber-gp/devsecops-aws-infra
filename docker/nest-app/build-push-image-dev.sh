#!/usr/bin/env bash

# ================================================================
# build-and-push.sh
# Builds a Docker image and pushes it to AWS ECR
#
# Usage:
#   ./build-and-push.sh [IMAGE_TAG]
#
# Arguments:
#   IMAGE_TAG  Optional. Defaults to git short SHA.
#              Example: ./build-and-push.sh 2.0.0
#
# Requirements:
#   - aws cli v2
#   - docker with BuildKit support
#   - jq
#   - IAM permissions: secretsmanager:GetSecretValue, ecr:*
# ================================================================

# ================================================================
# Strict mode — exit on error, unbound var, or pipe failure
# This is the most important line in any production bash script
# ================================================================
set -euo pipefail

# ================================================================
# Logging setup — all output goes to stdout AND a log file
# ================================================================
LOG_DIR="./logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/build-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# ================================================================
# Color codes — defined once, reused everywhere (DRY principle)
# ================================================================
RED='\033[31m'
GREEN='\033[32m'
CYAN='\033[36m'
YELLOW='\033[33m'
RESET='\033[0m'

# ================================================================
# Logging helpers
# ================================================================
log_info()    { echo -e "${CYAN}[INFO]  $*${RESET}"; }
log_success() { echo -e "${GREEN}[OK]    $*${RESET}"; }
log_warn()    { echo -e "${YELLOW}[WARN]  $*${RESET}"; }
log_error()   { echo -e "${RED}[ERROR] $*${RESET}" >&2; }

# ================================================================
# Trap — guaranteed cleanup on exit (success or failure)
# Unsets secrets from environment even if the script crashes
# ================================================================
cleanup() {
    local exit_code=$?
    log_info "Running cleanup..."
    unset PERSONAL_ACCESS_TOKEN_SECRET RDS_DB_PASSWORD_SECRET
    unset PERSONAL_ACCESS_TOKEN RDS_DB_PASSWORD SECRET_JSON
    if [ $exit_code -ne 0 ]; then
        log_error "Script exited with error code: $exit_code"
        log_error "Check log file for details: $LOG_FILE"
    fi
}
trap cleanup EXIT

# ================================================================
# Prerequisite checks — fail fast if required tools are missing
# Never assume tools exist in production environments
# ================================================================
check_prerequisites() {
    log_info "Checking prerequisites..."
    local missing=0

    for tool in aws docker jq; do
        if ! command -v "$tool" &>/dev/null; then
            log_error "Required tool not found: $tool"
            missing=1
        fi
    done

    # Verify Docker daemon is actually running
    if ! docker info &>/dev/null; then
        log_error "Docker daemon is not running"
        missing=1
    fi

    # Verify AWS CLI is authenticated
    if ! aws sts get-caller-identity &>/dev/null; then
        log_error "AWS CLI is not authenticated. Run 'aws configure' or check IAM role."
        missing=1
    fi

    if [ "$missing" -eq 1 ]; then
        log_error "Prerequisite checks failed. Aborting."
        exit 1
    fi

    log_success "All prerequisites satisfied."
}

# ================================================================
# Configuration — single source of truth, no duplicates
# AWS_ACCOUNT_ID retrieved dynamically — never hardcode account IDs
# IMAGE_TAG defaults to git short SHA for full traceability
# ================================================================
PROJECT_NAME="nest"
ENVIRONMENT="dev"
RECORD_NAME="demo"
DOMAIN_NAME="tolaniakintayo.xyz"
GITHUB_USERNAME="Tolani-Akintayo"
REPOSITORY_NAME="nest-app-code"
SERVICE_PROVIDER_FILE_NAME="AppServiceProvider"
APPLICATION_CODE_FILE_NAME="nest"
RDS_ENDPOINT="dev-nest-db.cbgq6s0gc62q.us-east-2.rds.amazonaws.com"
RDS_DB_NAME="applicationdb"
RDS_DB_USERNAME="admin"
SECRET_NAME="dev-nest-secrets"
AWS_REGION="us-east-2"
ECR_REPO_NAME="nest"
IMAGE_NAME="nest"

# IMAGE_TAG: use first argument if provided, otherwise use git short SHA
# This ensures every build is uniquely identifiable and traceable
if [ "${1:-}" != "" ]; then
    IMAGE_TAG="$1"
elif git rev-parse --short HEAD &>/dev/null; then
    IMAGE_TAG="$(git rev-parse --short HEAD)"
else
    IMAGE_TAG="$(date +%Y%m%d%H%M%S)"
    log_warn "Not a git repo. Using timestamp as IMAGE_TAG: $IMAGE_TAG"
fi

# Retrieve AWS account ID dynamically — never hardcode account IDs in scripts
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
FULL_IMAGE_URI="${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"

# ================================================================
# Input validation — catch empty variables before they cause
# cryptic failures deep in the build process
# ================================================================
validate_inputs() {
    log_info "Validating configuration..."
    local invalid=0

    local required_vars=(
        PROJECT_NAME ENVIRONMENT RECORD_NAME DOMAIN_NAME
        GITHUB_USERNAME REPOSITORY_NAME SERVICE_PROVIDER_FILE_NAME
        APPLICATION_CODE_FILE_NAME RDS_ENDPOINT RDS_DB_NAME
        RDS_DB_USERNAME SECRET_NAME AWS_REGION ECR_REPO_NAME
        IMAGE_NAME IMAGE_TAG AWS_ACCOUNT_ID
    )

    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            log_error "Required variable is empty or unset: $var"
            invalid=1
        fi
    done

    if [ "$invalid" -eq 1 ]; then
        log_error "Input validation failed. Aborting."
        exit 1
    fi

    log_success "All inputs validated."
}

# ================================================================
# Secrets retrieval
# ================================================================
retrieve_secrets() {
    log_info "Retrieving secrets from AWS Secrets Manager (secret: $SECRET_NAME)..."

    SECRET_JSON="$(aws secretsmanager get-secret-value \
        --secret-id "$SECRET_NAME" \
        --region "$AWS_REGION" \
        --query SecretString \
        --output text)"

    # Validate secret fields exist and are not null
    PERSONAL_ACCESS_TOKEN="$(echo "$SECRET_JSON" | jq -r '.personal_access_token')"
    RDS_DB_PASSWORD="$(echo "$SECRET_JSON" | jq -r '.password')"

    if [ "$PERSONAL_ACCESS_TOKEN" = "null" ] || [ -z "$PERSONAL_ACCESS_TOKEN" ]; then
        log_error "personal_access_token missing or null in Secrets Manager secret."
        exit 1
    fi

    if [ "$RDS_DB_PASSWORD" = "null" ] || [ -z "$RDS_DB_PASSWORD" ]; then
        log_error "password missing or null in Secrets Manager secret."
        exit 1
    fi

    # Export for BuildKit secret mounting
    export PERSONAL_ACCESS_TOKEN_SECRET="$PERSONAL_ACCESS_TOKEN"
    export RDS_DB_PASSWORD_SECRET="$RDS_DB_PASSWORD"

    log_success "Secrets retrieved successfully."
}

# ================================================================
# Docker build
# ================================================================

build_image() {
    log_info "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"

    export DOCKER_BUILDKIT=1

    # Build args stored in an array — immune to trailing whitespace bugs
    # that silently break \ line continuations
    local build_args=(
        --secret "id=personal_access_token,env=PERSONAL_ACCESS_TOKEN_SECRET"
        --secret "id=rds_db_password,env=RDS_DB_PASSWORD_SECRET"
        --build-arg "PROJECT_NAME=${PROJECT_NAME}"
        --build-arg "ENVIRONMENT=${ENVIRONMENT}"
        --build-arg "RECORD_NAME=${RECORD_NAME}"
        --build-arg "DOMAIN_NAME=${DOMAIN_NAME}"
        --build-arg "GITHUB_USERNAME=${GITHUB_USERNAME}"
        --build-arg "REPOSITORY_NAME=${REPOSITORY_NAME}"
        --build-arg "SERVICE_PROVIDER_FILE_NAME=${SERVICE_PROVIDER_FILE_NAME}"
        --build-arg "APPLICATION_CODE_FILE_NAME=${APPLICATION_CODE_FILE_NAME}"
        --build-arg "RDS_ENDPOINT=${RDS_ENDPOINT}"
        --build-arg "RDS_DB_NAME=${RDS_DB_NAME}"
        --build-arg "RDS_DB_USERNAME=${RDS_DB_USERNAME}"
        --label "build.git-sha=${IMAGE_TAG}"
        --label "build.timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        --label "build.environment=${ENVIRONMENT}"
        -t "${IMAGE_NAME}:${IMAGE_TAG}"
    )

    # Build context '.' is passed as a positional argument — always explicit,
    # never buried at the end of a continuation chain
    docker build "${build_args[@]}" -f Dockerfile.dev .

    log_success "Docker image built: ${IMAGE_NAME}:${IMAGE_TAG}"
}

# ================================================================
# ECR setup — idempotent repo creation with security best practices
# ================================================================
setup_ecr_repository() {
    log_info "Checking if ECR repository exists: $ECR_REPO_NAME..."

    # Attempt to describe the repo and capture both output and exit code
    # Using 'if' around the command prevents set -e from killing the script
    REPO_CHECK=$(aws ecr describe-repositories \
        --repository-names "$ECR_REPO_NAME" \
        --region "$AWS_REGION" 2>&1) && REPO_EXISTS=true || REPO_EXISTS=false

    if [ "$REPO_EXISTS" = "true" ]; then
        # Repo already exists — log it clearly and skip creation entirely
        log_warn "ECR repository '$ECR_REPO_NAME' already exists. Skipping creation."
        log_info "Existing repo URI: ${ECR_REGISTRY}/${ECR_REPO_NAME}"
        return 0
    fi

    # Repo does not exist — create it with security best practices
    log_info "ECR repository not found. Creating: $ECR_REPO_NAME..."

    aws ecr create-repository \
        --repository-name "$ECR_REPO_NAME" \
        --region "$AWS_REGION" \
        --image-scanning-configuration scanOnPush=true \
        --encryption-configuration encryptionType=AES256

    # Apply lifecycle policy — keep only last 10 images
    # Prevents ECR storage costs from growing unbounded in production
    aws ecr put-lifecycle-policy \
        --repository-name "$ECR_REPO_NAME" \
        --region "$AWS_REGION" \
        --lifecycle-policy-text '{
            "rules": [
                {
                    "rulePriority": 1,
                    "description": "Keep last 10 images",
                    "selection": {
                        "tagStatus": "any",
                        "countType": "imageCountMoreThan",
                        "countNumber": 10
                    },
                    "action": { "type": "expire" }
                }
            ]
        }'

    log_success "ECR repository created with scanning and lifecycle policy: $ECR_REPO_NAME"
}

# ================================================================
# Push to ECR
# ================================================================
push_to_ecr() {
    log_info "Authenticating Docker to ECR..."
    aws ecr get-login-password --region "$AWS_REGION" \
        | docker login --username AWS --password-stdin "$ECR_REGISTRY"
    log_success "Docker authenticated to ECR."

    log_info "Tagging image for ECR: $FULL_IMAGE_URI"
    docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "$FULL_IMAGE_URI"

    log_info "Pushing image to ECR: $FULL_IMAGE_URI"
    docker push "$FULL_IMAGE_URI"
    log_success "Image pushed successfully: $FULL_IMAGE_URI"
}

# ================================================================
# Main — explicit execution order
# ================================================================
main() {
    echo ""
    log_info "========================================"
    log_info " Build & Push: ${IMAGE_NAME}:${IMAGE_TAG}"
    log_info " Environment:  ${ENVIRONMENT}"
    log_info " Region:       ${AWS_REGION}"
    log_info " Log file:     ${LOG_FILE}"
    log_info "========================================"
    echo ""

    check_prerequisites
    validate_inputs
    retrieve_secrets
    build_image
    setup_ecr_repository
    push_to_ecr

    echo ""
    log_success "========================================"
    log_success " All operations completed successfully!"
    log_success " Image: ${FULL_IMAGE_URI}"
    log_success "========================================"
    echo ""
}

main "$@"