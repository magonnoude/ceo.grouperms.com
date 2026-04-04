#!/bin/bash
# =============================================================================
# create-api-gateway.sh
# Creates a new API Gateway REST API in eu-west-3 for ceo.grouperms.com
# with correct CORS on /contact and /newsletter
#
# Prerequisites:
#   - AWS CLI configured
#   - Lambda ceo-contact-handler deployed in eu-west-3
#   - Your AWS Account ID ready
#
# Usage: bash create-api-gateway.sh YOUR_ACCOUNT_ID
# =============================================================================

set -e

ACCOUNT_ID="${1}"
REGION="eu-west-3"
LAMBDA_NAME="ceo-contact-handler"
STAGE="prod"
ORIGIN="https://ceo.grouperms.com"

if [ -z "$ACCOUNT_ID" ]; then
  echo "Usage: bash create-api-gateway.sh YOUR_ACCOUNT_ID"
  echo "Find your Account ID: AWS Console → top-right corner"
  exit 1
fi

LAMBDA_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${LAMBDA_NAME}"

echo "======================================================"
echo " Creating API Gateway in ${REGION}"
echo " Lambda: ${LAMBDA_ARN}"
echo " Origin: ${ORIGIN}"
echo "======================================================"
echo ""

# ── Step 1: Create REST API ───────────────────────────────────────────────────
echo "Step 1: Creating REST API..."
API_ID=$(aws apigateway create-rest-api \
  --name "ceo-grouperms-api" \
  --description "Contact and newsletter API for ceo.grouperms.com" \
  --region $REGION \
  --endpoint-configuration types=REGIONAL \
  --query 'id' --output text)

echo "  ✓ API created: ${API_ID}"

# Get root resource ID
ROOT_ID=$(aws apigateway get-resources \
  --rest-api-id $API_ID \
  --region $REGION \
  --query 'items[?path==`/`].id' --output text)

echo "  ✓ Root resource: ${ROOT_ID}"

# ── Step 2: Create /contact resource ─────────────────────────────────────────
echo ""
echo "Step 2: Creating /contact resource..."
CONTACT_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_ID \
  --path-part "contact" \
  --region $REGION \
  --query 'id' --output text)

echo "  ✓ /contact resource: ${CONTACT_ID}"

# POST method for /contact
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $CONTACT_ID \
  --http-method POST \
  --authorization-type NONE \
  --region $REGION > /dev/null

# Lambda integration for POST /contact
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $CONTACT_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
  --region $REGION > /dev/null

echo "  ✓ POST /contact → Lambda integration"

# OPTIONS method for /contact (CORS preflight)
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $CONTACT_ID \
  --http-method OPTIONS \
  --authorization-type NONE \
  --region $REGION > /dev/null

aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $CONTACT_ID \
  --http-method OPTIONS \
  --type MOCK \
  --request-templates '{"application/json": "{\"statusCode\": 200}"}' \
  --region $REGION > /dev/null

aws apigateway put-method-response \
  --rest-api-id $API_ID \
  --resource-id $CONTACT_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters '{
    "method.response.header.Access-Control-Allow-Headers": false,
    "method.response.header.Access-Control-Allow-Methods": false,
    "method.response.header.Access-Control-Allow-Origin": false
  }' \
  --region $REGION > /dev/null

aws apigateway put-integration-response \
  --rest-api-id $API_ID \
  --resource-id $CONTACT_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters "{
    \"method.response.header.Access-Control-Allow-Headers\": \"'Content-Type,X-Amz-Date,Authorization,X-Api-Key'\",
    \"method.response.header.Access-Control-Allow-Methods\": \"'POST,OPTIONS'\",
    \"method.response.header.Access-Control-Allow-Origin\": \"'${ORIGIN}'\"
  }" \
  --region $REGION > /dev/null

echo "  ✓ OPTIONS /contact → CORS preflight configured"

# ── Step 3: Create /newsletter resource ──────────────────────────────────────
echo ""
echo "Step 3: Creating /newsletter resource..."
NEWSLETTER_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_ID \
  --path-part "newsletter" \
  --region $REGION \
  --query 'id' --output text)

echo "  ✓ /newsletter resource: ${NEWSLETTER_ID}"

# POST method for /newsletter
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $NEWSLETTER_ID \
  --http-method POST \
  --authorization-type NONE \
  --region $REGION > /dev/null

# Lambda integration for POST /newsletter
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $NEWSLETTER_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
  --region $REGION > /dev/null

echo "  ✓ POST /newsletter → Lambda integration"

# OPTIONS method for /newsletter (CORS preflight)
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $NEWSLETTER_ID \
  --http-method OPTIONS \
  --authorization-type NONE \
  --region $REGION > /dev/null

aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $NEWSLETTER_ID \
  --http-method OPTIONS \
  --type MOCK \
  --request-templates '{"application/json": "{\"statusCode\": 200}"}' \
  --region $REGION > /dev/null

aws apigateway put-method-response \
  --rest-api-id $API_ID \
  --resource-id $NEWSLETTER_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters '{
    "method.response.header.Access-Control-Allow-Headers": false,
    "method.response.header.Access-Control-Allow-Methods": false,
    "method.response.header.Access-Control-Allow-Origin": false
  }' \
  --region $REGION > /dev/null

aws apigateway put-integration-response \
  --rest-api-id $API_ID \
  --resource-id $NEWSLETTER_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters "{
    \"method.response.header.Access-Control-Allow-Headers\": \"'Content-Type,X-Amz-Date,Authorization,X-Api-Key'\",
    \"method.response.header.Access-Control-Allow-Methods\": \"'POST,OPTIONS'\",
    \"method.response.header.Access-Control-Allow-Origin\": \"'${ORIGIN}'\"
  }" \
  --region $REGION > /dev/null

echo "  ✓ OPTIONS /newsletter → CORS preflight configured"

# ── Step 4: Grant Lambda invoke permission ────────────────────────────────────
echo ""
echo "Step 4: Granting API Gateway permission to invoke Lambda..."

aws lambda add-permission \
  --function-name $LAMBDA_NAME \
  --statement-id "apigateway-contact-${API_ID}" \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/POST/contact" \
  --region $REGION > /dev/null

aws lambda add-permission \
  --function-name $LAMBDA_NAME \
  --statement-id "apigateway-newsletter-${API_ID}" \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/POST/newsletter" \
  --region $REGION > /dev/null

echo "  ✓ Lambda invoke permissions granted"

# ── Step 5: Deploy to prod stage ─────────────────────────────────────────────
echo ""
echo "Step 5: Deploying to '${STAGE}' stage..."

aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name $STAGE \
  --description "Initial deployment — ceo.grouperms.com" \
  --region $REGION > /dev/null

echo "  ✓ Deployed to stage: ${STAGE}"

# ── Output ────────────────────────────────────────────────────────────────────
NEW_ENDPOINT="https://${API_ID}.execute-api.${REGION}.amazonaws.com/${STAGE}"

echo ""
echo "======================================================"
echo " ✅ API Gateway created successfully!"
echo "======================================================"
echo ""
echo " API ID:      ${API_ID}"
echo " Region:      ${REGION}"
echo " Stage:       ${STAGE}"
echo ""
echo " Contact URL:    ${NEW_ENDPOINT}/contact"
echo " Newsletter URL: ${NEW_ENDPOINT}/newsletter"
echo ""
echo "======================================================"
echo " NEXT STEP — update main.js with new URLs:"
echo "======================================================"
echo ""
echo " Run this command from your project root:"
echo ""
echo "   bash update-api-endpoint.sh ${API_ID}"
echo ""
echo " This replaces the old endpoint in main.js and"
echo " commits + pushes to trigger CI/CD deployment."
echo "======================================================"

# Save the API ID for the next script
echo $API_ID > .new-api-id.tmp
