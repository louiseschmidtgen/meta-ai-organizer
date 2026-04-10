#!/usr/bin/env bash
# check-pr-status.sh — Poll CI status for a microk8s PR
set -euo pipefail

REPO="canonical/microk8s"
PR_NUM="${1:-5453}"
MAX_POLLS="${2:-20}"
INTERVAL="${3:-30}"

echo "=== Checking CI status for ${REPO}#${PR_NUM} ==="
echo "    (polling every ${INTERVAL}s, max ${MAX_POLLS} attempts)"
echo ""

for i in $(seq 1 "$MAX_POLLS"); do
  echo "--- Poll $i ($(date +%H:%M:%S)) ---"
  output=$(GH_PAGER=cat gh pr checks "$PR_NUM" --repo "$REPO" 2>&1) || true
  echo "$output"

  if echo "$output" | grep -q "All checks were successful"; then
    echo ""
    echo "ALL CI CHECKS PASSED"
    exit 0
  fi

  # If no pending checks remain, we have a final result
  if ! echo "$output" | grep -q "pending"; then
    echo ""
    echo "CI FINISHED WITH FAILURES"
    exit 1
  fi

  if [[ "$i" -lt "$MAX_POLLS" ]]; then
    echo "Waiting ${INTERVAL}s..."
    sleep "$INTERVAL"
  fi
done

echo "TIMEOUT: checks still pending after $((MAX_POLLS * INTERVAL))s"
exit 2
