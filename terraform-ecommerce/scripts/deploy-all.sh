#!/usr/bin/env bash
# ==============================================================================
# deploy-all.sh - Master End-to-End eCommerce Deployment Script
# 
# Orchestrates:
# 1. Terraform apply (Infrastructure, VPC, RDS, Cognito, ALB, ECS, API GW, S3, CloudFront, Route53, ACM)
# 2. Docker container images build & push to Amazon ECR
# 3. Product images upload to S3 & catalog seeding into DynamoDB
# 4. React frontend configuration, build, S3 sync & CloudFront cache invalidation
# 5. Live deployment verification & summary of endpoints
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DEV_DIR="${ROOT_DIR}/environments/dev"
DATA_DIR="${ROOT_DIR}/data"

echo "=============================================================================="
echo "🚀 Starting Full End-to-End eCommerce Application Deployment"
echo "=============================================================================="

# ------------------------------------------------------------------------------
# STEP 1: Apply Terraform Infrastructure
# ------------------------------------------------------------------------------
echo ""
echo "▶ [1/4] Applying Terraform Infrastructure (environments/dev)..."
echo "------------------------------------------------------------------------------"
cd "${DEV_DIR}"
terraform init
terraform apply -auto-approve

# Extract necessary outputs
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")
S3_BUCKET=$(terraform output -raw frontend_bucket_name 2>/dev/null || echo "")
CF_DIST_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")
API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
CUSTOM_DOMAIN=$(terraform output -raw custom_domain_url 2>/dev/null || echo "")
CF_DEFAULT_URL=$(terraform output -raw cloudfront_url 2>/dev/null || echo "")

if [ -z "${S3_BUCKET}" ]; then
  S3_BUCKET=$(aws s3api list-buckets --query "Buckets[?contains(Name, 'ecommerce-frontend-')].Name" --output text 2>/dev/null | awk '{print $1}')
fi

echo "✔ Infrastructure ready!"
echo "  • S3 Bucket      : ${S3_BUCKET}"
echo "  • CloudFront ID  : ${CF_DIST_ID}"
echo "  • API Gateway    : ${API_URL}"

# ------------------------------------------------------------------------------
# STEP 2: Build & Push Microservices Container Images to ECR
# ------------------------------------------------------------------------------
echo ""
echo "▶ [2/4] Building and Pushing Docker Microservices to ECR..."
echo "------------------------------------------------------------------------------"
"${SCRIPT_DIR}/build-and-push-images.sh"

echo "✔ Microservices images built and pushed to ECR!"

# ------------------------------------------------------------------------------
# STEP 3: Upload Product Images & Seed DynamoDB Catalog
# ------------------------------------------------------------------------------
echo ""
echo "▶ [3/4] Uploading Images to S3 & Seeding DynamoDB Catalog..."
echo "------------------------------------------------------------------------------"
cd "${DATA_DIR}"

if [ -n "${S3_BUCKET}" ]; then
  echo "Uploading product images to S3..."
  ./upload-images-to-s3.sh "${S3_BUCKET}" "${AWS_REGION}"
  
  IMAGE_HOST="${CUSTOM_DOMAIN:-${CF_DEFAULT_URL}}"
  if [ -z "${IMAGE_HOST}" ]; then
    IMAGE_HOST="https://${S3_BUCKET}.s3.${AWS_REGION}.amazonaws.com"
  fi

  echo "Updating product image URLs in products.json with host: ${IMAGE_HOST}..."
  ./update-product-image-urls.sh "${IMAGE_HOST}"
fi

echo "Loading products into DynamoDB (ecommerce-products)..."
./load-products.sh "${AWS_REGION}"

echo "✔ Products successfully seeded into DynamoDB!"

# ------------------------------------------------------------------------------
# STEP 4: Build & Deploy React Frontend Application
# ------------------------------------------------------------------------------
echo ""
echo "▶ [4/4] Configuring, Building & Deploying Frontend to CloudFront..."
echo "------------------------------------------------------------------------------"
cd "${ROOT_DIR}"
"${SCRIPT_DIR}/deploy-frontend.sh"

# ------------------------------------------------------------------------------
# DEPLOYMENT SUMMARY & VERIFICATION
# ------------------------------------------------------------------------------
echo ""
echo "=============================================================================="
echo "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "=============================================================================="
echo "Access your live application at:"
if [ -n "${CUSTOM_DOMAIN}" ]; then
  echo "  🌐 Primary Custom Domain : ${CUSTOM_DOMAIN}"
  echo "  🌐 Subdomain (www)       : https://www.mycloudhomelab.click"
  echo "  🌐 Subdomain (ecommerce) : https://ecommerce.mycloudhomelab.click"
fi
echo "  ☁️  CloudFront Default    : ${CF_DEFAULT_URL}"
echo "  🔌 API Gateway Endpoint  : ${API_URL}"
echo "=============================================================================="
