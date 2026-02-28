#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://localhost:8000}"
COUNT="${2:-3000}"
CONCURRENCY="${3:-1000}"
ENDPOINT="${4:-/v1/myendpoint}"

echo "Load test: $COUNT requests, $CONCURRENCY concurrent, GET $BASE_URL$ENDPOINT"
START=$(date +%s.%N)

# Portable number sequence (works on macOS without coreutils)
count_to_n() { i=0; while [ "$i" -lt "$1" ]; do echo "$i"; i=$((i+1)); done; }
count_to_n "$COUNT" | xargs -P "$CONCURRENCY" -I {} curl -s -o /dev/null -w "%{http_code}\n" "$BASE_URL$ENDPOINT" \
  | sort | uniq -c

END=$(date +%s.%N)
ELAPSED=$(awk "BEGIN { printf \"%.2f\", $END - $START }")
RPS=$(awk "BEGIN { printf \"%.0f\", $COUNT / ($END - $START) }" 2>/dev/null || echo "N/A")
echo "Total: $COUNT requests in ${ELAPSED}s (~$RPS req/s)"
