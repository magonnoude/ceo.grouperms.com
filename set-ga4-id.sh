#!/bin/bash
# =============================================================================
# set-ga4-id.sh — Replace GA4 placeholder with your real ceo property ID
# Usage: bash set-ga4-id.sh G-XXXXXXXXXX
# Run once from the root of your project after creating the GA4 property
# =============================================================================

if [ -z "$1" ]; then
  echo "Usage: bash set-ga4-id.sh G-XXXXXXXXXX"
  echo "Get your ID from: analytics.google.com → Admin → Data Streams → your stream"
  exit 1
fi

NEW_ID="$1"
PLACEHOLDER="G-CEO-PROPERTY-ID"

# Validate format
if [[ ! "$NEW_ID" =~ ^G-[A-Z0-9]+$ ]]; then
  echo "Error: GA4 ID must start with G- followed by letters/numbers (e.g. G-ABC123XYZ)"
  exit 1
fi

echo "Replacing $PLACEHOLDER with $NEW_ID in all HTML and JS files..."

# HTML files
for f in *.html articles/*.html; do
  if [ -f "$f" ] && grep -q "$PLACEHOLDER" "$f"; then
    sed -i "s/$PLACEHOLDER/$NEW_ID/g" "$f"
    echo "  ✓ $f"
  fi
done

# JS files
for f in js/*.js; do
  if [ -f "$f" ] && grep -q "$PLACEHOLDER" "$f"; then
    sed -i "s/$PLACEHOLDER/$NEW_ID/g" "$f"
    echo "  ✓ $f"
  fi
done

echo ""
echo "Done. Files updated with GA4 ID: $NEW_ID"
echo ""
echo "Next steps:"
echo "  1. git add ."
echo "  2. git commit -m 'config: set GA4 property ID $NEW_ID for ceo.grouperms.com'"
echo "  3. git push"
echo "  → GitHub Actions will deploy automatically"
