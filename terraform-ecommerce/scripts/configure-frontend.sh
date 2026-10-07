#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEV_DIR="${PROJECT_DIR}/environments/dev"
CONFIG_FILE="${PROJECT_DIR}/frontend/react-app/src/aws-config.js"

# 1. Fetch values from Terraform outputs if not provided as arguments
cd "${DEV_DIR}"
USER_POOL_ID="${1:-$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "")}"
CLIENT_ID="${2:-$(terraform output -raw cognito_client_id 2>/dev/null || echo "")}"
API_URL="${3:-$(terraform output -raw api_gateway_url 2>/dev/null || echo "")}"

# Fallback: check AWS SSM if needed
if [ -z "${USER_POOL_ID}" ]; then
  echo "Fetching Cognito User Pool ID from AWS..."
  USER_POOL_ID=$(aws cognito-idp list-user-pools --max-results 10 --region us-east-1 --query "UserPools[?Name=='ecommerce-user-pool'].Id" --output text 2>/dev/null || echo "")
fi

if [ -z "${CLIENT_ID}" ] && [ -n "${USER_POOL_ID}" ]; then
  echo "Fetching Cognito App Client ID from AWS..."
  CLIENT_ID=$(aws cognito-idp list-user-pool-clients --user-pool-id "${USER_POOL_ID}" --region us-east-1 --query "UserPoolClients[0].ClientId" --output text 2>/dev/null || echo "")
fi

if [ -z "${API_URL}" ]; then
  echo "Fetching HTTP API Gateway URL from AWS..."
  API_ID=$(aws apigatewayv2 get-apis --region us-east-1 --query "Items[?Name=='ecommerce-API-GTW'].ApiId" --output text 2>/dev/null || echo "")
  if [ -n "${API_ID}" ]; then
    API_URL="https://${API_ID}.execute-api.us-east-1.amazonaws.com"
  fi
fi

# Remove trailing slash from API_URL if present
API_URL="${API_URL%/}"

echo "=========================================="
echo "Configuring Frontend aws-config.js"
echo "=========================================="
echo "Cognito User Pool ID : ${USER_POOL_ID:-[NOT SET]}"
echo "Cognito Client ID    : ${CLIENT_ID:-[NOT SET]}"
echo "API Gateway URL      : ${API_URL:-[NOT SET]}"
echo "Target File          : ${CONFIG_FILE}"

cat <<EOF > "${CONFIG_FILE}"
const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: '${USER_POOL_ID}',
      userPoolClientId: '${CLIENT_ID}',
      loginWith: {
        email: true,
      },
    }
  },
  API: {
    baseUrl: '${API_URL}'
  }
};

export default awsConfig;
EOF

echo ">>> Successfully updated ${CONFIG_FILE}!"
