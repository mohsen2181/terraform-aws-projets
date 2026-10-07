#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
FRONTEND_DIR="${PROJECT_DIR}/frontend/react-app"

# 1. Automatically configure aws-config.js with latest Terraform / AWS outputs
"${SCRIPT_DIR}/configure-frontend.sh"

# 2. Get S3 bucket name and CloudFront distribution ID from Terraform outputs
cd "${PROJECT_DIR}/environments/dev"
S3_BUCKET=$(terraform output -raw frontend_bucket_name 2>/dev/null || echo "")
CF_DIST_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")

if [ -z "${S3_BUCKET}" ]; then
  echo "Fetching S3 Frontend bucket from AWS..."
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  S3_BUCKET=$(aws s3api list-buckets --query "Buckets[?contains(Name, 'ecommerce-frontend-')].Name" --output text 2>/dev/null | awk '{print $1}')
fi

if [ -z "${S3_BUCKET}" ]; then
  echo "ERROR: S3 frontend bucket not found. Please provide it: $0 <bucket-name> [cloudfront-dist-id]"
  exit 1
fi

echo "=========================================="
echo "Building React Application..."
echo "=========================================="
cd "${FRONTEND_DIR}"
npm install
npm run build

echo "=========================================="
echo "Syncing build to S3: s3://${S3_BUCKET}..."
echo "=========================================="
aws s3 sync build/ "s3://${S3_BUCKET}" --delete --exclude "images/*"

if [ -n "${CF_DIST_ID}" ]; then
  echo "=========================================="
  echo "Invalidating CloudFront Cache: ${CF_DIST_ID}..."
  echo "=========================================="
  aws cloudfront create-invalidation --distribution-id "${CF_DIST_ID}" --paths "/*"
fi

echo ">>> Frontend deployment completed successfully!"
