#!/bin/bash
# =============================================================================
# update-api-endpoint.sh
# Replaces the old API Gateway endpoint in main.js with the new eu-west-3 one
#
# Usage: bash update-api-endpoint.sh NEW_API_ID
# Example: bash update-api-endpoint.sh abc123def
# =============================================================================

set -e

NEW_API_ID="${1}"
REGION="eu-west-3"
STAGE="prod"

if [ -z "$NEW_API_ID" ]; then
  # Try reading from temp file left by create-api-gateway.sh
  if [ -f ".new-api-id.tmp" ]; then
    NEW_API_ID=$(cat .new-api-id.tmp)
    echo "Using API ID from previous step: ${NEW_API_ID}"
  else
    echo "Usage: bash update-api-endpoint.sh NEW_API_ID"
    echo "The NEW_API_ID was printed at the end of create-api-gateway.sh"
    exit 1
  fi
fi

OLD_ENDPOINT="e9hpqlfmz2.execute-api.us-east-1.amazonaws.com/prod"
NEW_ENDPOINT="${NEW_API_ID}.execute-api.${REGION}.amazonaws.com/${STAGE}"

echo "Updating API endpoint in main.js..."
echo "  Old: ${OLD_ENDPOINT}"
echo "  New: ${NEW_ENDPOINT}"
echo ""

# Update main.js
if grep -q "$OLD_ENDPOINT" js/main.js; then
  sed -i "s|${OLD_ENDPOINT}|${NEW_ENDPOINT}|g" js/main.js
  echo "  ✓ js/main.js updated"
else
  echo "  ⚠ Old endpoint not found in js/main.js — may already be updated"
fi

# Verify
echo ""
echo "Verifying new URLs in main.js:"
grep 'execute-api' js/main.js

# Cleanup temp file
rm -f .new-api-id.tmp

echo ""
echo "======================================================"
echo " Test the new endpoints from terminal:"
echo "======================================================"
echo ""
echo " curl -X POST https://${NEW_ENDPOINT}/contact \\"
echo "   -H 'Content-Type: application/json' \\"
echo "   -d '{\"name\":\"Test\",\"email\":\"modeste.agonnoude@grouperms.com\",\"message\":\"CORS test from eu-west-3\",\"timestamp\":\"2026-04-03T10:00:00Z\",\"page\":\"/contact.html\"}'"
echo ""
echo " curl -X POST https://${NEW_ENDPOINT}/newsletter \\"
echo "   -H 'Content-Type: application/json' \\"
echo "   -d '{\"email\":\"modeste.agonnoude@grouperms.com\",\"source\":\"/index.html\",\"timestamp\":\"2026-04-03T10:00:00Z\"}'"
echo ""
echo "======================================================"
echo " Deploy when tests pass:"
echo "======================================================"
echo ""
echo "  git add js/main.js"
echo "  git commit -m 'fix: use new API Gateway eu-west-3 with CORS'"
echo "  git push"
echo "======================================================"
