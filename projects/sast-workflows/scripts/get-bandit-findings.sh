#!/bin/bash
# get-bandit-findings.sh — Extract exact file:line:code from failed bandit runs
#
# Usage:
#   bash get-bandit-findings.sh <repo> [<repo> ...]
#
# Outputs lines like:
#   === org/repo ===
#   file.py:42:B324
#   file.py:99:B602
#
# Use this output to build fix_repo() calls for fix-bandit-findings.sh

set -euo pipefail

export GH_PAGER=cat

for repo in "$@"; do
  echo "=== $repo ==="
  run_id=$(gh run list --repo "$repo" --workflow bandit.yaml --branch KU-5612/sast-workflows --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null)
  if [[ -z "$run_id" ]]; then
    echo "  (no bandit run found)"
    continue
  fi

  gh run view "$run_id" --repo "$repo" --log-failed 2>/dev/null | while IFS= read -r line; do
    if echo "$line" | grep -q ">> Issue:"; then
      code=$(echo "$line" | grep -oP 'B[0-9]{3}')
      issue=$(echo "$line" | grep -oP '\[.*?\]' | head -1)
    fi
    if echo "$line" | grep -q "Location:"; then
      location=$(echo "$line" | grep -oP '\./[^ ]+')
      # Strip ./ prefix
      location="${location#./}"
      file=$(echo "$location" | cut -d: -f1)
      lineno=$(echo "$location" | cut -d: -f2)
      echo "  $file:$lineno:$code"
    fi
  done
  echo ""
done
