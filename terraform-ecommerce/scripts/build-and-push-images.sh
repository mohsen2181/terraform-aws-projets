#!/usr/bin/env bash
set -e

# Determine script and project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 1. Retrieve Account ID and Region dynamically
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "=========================================="
echo "Logging in to Amazon ECR: ${ECR_REGISTRY}..."
echo "=========================================="
aws ecr get-login-password --region "${REGION}" | \
  docker login --username AWS --password-stdin "${ECR_REGISTRY}"

# 2. Build, Tag, and Push each microservice
SERVICES=("product-service" "cart-service" "user-service" "order-service")

for SVC in "${SERVICES[@]}"; do
  echo "=========================================="
  echo "Building Docker image: ${SVC}..."
  echo "=========================================="
  
  # Support both ./backend and ./services directory names
  if [ -d "${PROJECT_DIR}/backend/${SVC}" ]; then
    CONTEXT_DIR="${PROJECT_DIR}/backend/${SVC}"
  elif [ -d "${PROJECT_DIR}/services/${SVC}" ]; then
    CONTEXT_DIR="${PROJECT_DIR}/services/${SVC}"
  else
    echo "ERROR: Directory for ${SVC} not found in ${PROJECT_DIR}/backend or ${PROJECT_DIR}/services!"
    exit 1
  fi

  docker build -t "ecommerce/${SVC}:latest" "${CONTEXT_DIR}"
  docker tag "ecommerce/${SVC}:latest" "${ECR_REGISTRY}/ecommerce/${SVC}:latest"
  
  echo "Pushing ${SVC} to ECR..."
  docker push "${ECR_REGISTRY}/ecommerce/${SVC}:latest"
  echo ">>> ${SVC} pushed successfully!"
done

echo "=========================================="
echo "All 4 microservice container images pushed to ECR!"
echo "=========================================="
