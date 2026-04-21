#!/bin/bash

# ================================================================
# Define ECR registry
# ================================================================

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# ================================================================
# Create ECR repository (if needed)
# ================================================================

aws ecr describe-repositories --repository-names "$IMAGE_NAME" --region "$AWS_REGION" 2>/dev/null || \
    aws ecr create-repository --repository-name "$IMAGE_NAME" --region "$AWS_REGION"

# ================================================================
# Authenticate Docker to ECR
# ================================================================

aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

# ================================================================
# Tag the image - two tags, same image
# 1. Semantic version tag  → what ECS and humans reference
# 2. SHA tag               → what the pipeline reads next run
# ================================================================

docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ECR_REGISTRY}/${IMAGE_NAME}:sha-${APP_COMMIT_SHA}"

# ================================================================
# Push both image tags to ECR
# ================================================================

echo "Pushing version tag: ${IMAGE_TAG}"
docker push "${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "Pushing SHA tag: sha-${APP_COMMIT_SHA}"
docker push "${ECR_REGISTRY}/${IMAGE_NAME}:sha-${APP_COMMIT_SHA}"

echo "Successfully pushed:"
echo "  ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
echo "  ${ECR_REGISTRY}/${IMAGE_NAME}:sha-${APP_COMMIT_SHA}"
