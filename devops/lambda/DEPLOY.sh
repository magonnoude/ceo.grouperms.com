# Lambda Contact Handler — Deployment Guide
# ceo.grouperms.com
# Updated: April 2026

# ═══════════════════════════════════════════════════════════════════════════════
# ARCHITECTURE OVERVIEW
# ═══════════════════════════════════════════════════════════════════════════════
#
#   Browser → API Gateway (e9hpqlfmz2) → Lambda (contact-handler)
#                                              ↓              ↓
#                                           SES            DynamoDB
#                                     (email delivery)  (audit log)
#
# Endpoints:
#   POST /prod/contact/    → contact form
#   POST /prod/newsletter  → newsletter subscription
#
# ═══════════════════════════════════════════════════════════════════════════════
# STEP 1 — PACKAGE THE LAMBDA
# ═══════════════════════════════════════════════════════════════════════════════

cd lambda/
zip -r contact-handler.zip lambda_function.py

# No external dependencies — uses only Python stdlib + boto3 (included in Lambda runtime)

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 2 — CREATE OR UPDATE THE LAMBDA FUNCTION
# ═══════════════════════════════════════════════════════════════════════════════

# If creating fresh:
aws lambda create-function \
  --function-name ceo-contact-handler \
  --runtime python3.12 \
  --role arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-contact-role \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://contact-handler.zip \
  --timeout 15 \
  --memory-size 128 \
  --region eu-west-3

# If updating existing function:
aws lambda update-function-code \
  --function-name ceo-contact-handler \
  --zip-file fileb://contact-handler.zip \
  --region eu-west-3

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 3 — SET ENVIRONMENT VARIABLES
# ═══════════════════════════════════════════════════════════════════════════════

aws lambda update-function-configuration \
  --function-name ceo-contact-handler \
  --environment "Variables={
    RECAPTCHA_SECRET_KEY=YOUR_RECAPTCHA_V3_SECRET_KEY,
    SES_FROM_EMAIL=no-reply@grouperms.com,
    SES_TO_EMAIL=modeste.agonnoude@grouperms.com,
    DYNAMODB_TABLE=ceo-contact-submissions,
    ALLOWED_ORIGIN=https://ceo.grouperms.com,
    RECAPTCHA_MIN_SCORE=0.5
  }" \
  --region eu-west-3

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 4 — IAM ROLE POLICY (attach to Lambda execution role)
# ═══════════════════════════════════════════════════════════════════════════════
# See: iam-policy.json in this folder

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 5 — DYNAMODB TABLE
# ═══════════════════════════════════════════════════════════════════════════════

aws dynamodb create-table \
  --table-name ceo-contact-submissions \
  --attribute-definitions AttributeName=submission_id,AttributeType=S \
  --key-schema AttributeName=submission_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-3

# Add TTL (optional — auto-delete after 1 year for GDPR compliance)
aws dynamodb update-time-to-live \
  --table-name ceo-contact-submissions \
  --time-to-live-specification "Enabled=true,AttributeName=ttl" \
  --region eu-west-3

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 6 — SES VERIFICATION
# ═══════════════════════════════════════════════════════════════════════════════

# Verify sender domain (if not already done for grouperms.com)
aws ses verify-domain-identity \
  --domain grouperms.com \
  --region eu-west-3

# Verify individual sender email
aws ses verify-email-identity \
  --email-address no-reply@grouperms.com \
  --region eu-west-3

# Verify recipient
aws ses verify-email-identity \
  --email-address modeste.agonnoude@grouperms.com \
  --region eu-west-3

# If SES is in sandbox, request production access:
# AWS Console → SES → Account Dashboard → Request Production Access

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 7 — API GATEWAY CORS (confirm settings)
# ═══════════════════════════════════════════════════════════════════════════════
# In AWS Console → API Gateway → e9hpqlfmz2 → each resource:
#
#   /contact  [POST] → Integration: Lambda ceo-contact-handler
#   /contact  [OPTIONS] → Mock integration returning CORS headers
#   /newsletter [POST] → Integration: Lambda ceo-contact-handler
#   /newsletter [OPTIONS] → Mock integration
#
# Method Response for POST → Add headers:
#   Access-Control-Allow-Origin
#   Access-Control-Allow-Methods
#   Access-Control-Allow-Headers
#
# Note: The Lambda now returns CORS headers directly in the response,
# so API Gateway pass-through mode (LAMBDA_PROXY) is recommended.

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 8 — TEST
# ═══════════════════════════════════════════════════════════════════════════════

# Test contact endpoint
curl -X POST \
  https://e9hpqlfmz2.execute-api.us-east-1.amazonaws.com/prod/contact/ \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "company": "Test Corp",
    "interest": "advisory",
    "message": "This is a test message from the deployment script.",
    "recaptcha_token": "test-token",
    "timestamp": "2026-04-03T10:00:00Z",
    "page": "/contact.html"
  }'

# Test newsletter endpoint
curl -X POST \
  https://e9hpqlfmz2.execute-api.us-east-1.amazonaws.com/prod/newsletter \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "source": "/index.html",
    "timestamp": "2026-04-03T10:00:00Z"
  }'

# ═══════════════════════════════════════════════════════════════════════════════
# MONITORING
# ═══════════════════════════════════════════════════════════════════════════════

# View Lambda logs
aws logs tail /aws/lambda/ceo-contact-handler --follow --region eu-west-3

# View DynamoDB submissions
aws dynamodb scan \
  --table-name ceo-contact-submissions \
  --region eu-west-3 \
  --query 'Items[*].{id:submission_id.S,type:type.S,email:email.S,ts:created_at.S}' \
  --output table
