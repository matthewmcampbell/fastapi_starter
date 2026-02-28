#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://localhost:8000}"

echo "Sanity check: GET $BASE_URL/healthz"
HTTP_CODE=$(curl -s -o /tmp/sanity-check-out -w "%{http_code}" "$BASE_URL/healthz")
BODY=$(cat /tmp/sanity-check-out)
rm -f /tmp/sanity-check-out

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "OK ($HTTP_CODE) $BODY"
  exit 0
else
  echo "FAIL ($HTTP_CODE) $BODY"
  exit 1
fi
