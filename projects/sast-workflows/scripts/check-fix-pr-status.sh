#!/bin/bash
# check-fix-pr-status.sh — Check the state of all bandit fix PRs
#
# Usage:
#   bash check-fix-pr-status.sh <progress-yaml>
#
# Reports OPEN/MERGED/CLOSED for each bandit-fix-pr in PROGRESS.yaml.

set -euo pipefail

export GH_PAGER=cat

PROGRESS="${1:?Usage: check-fix-pr-status.sh <progress-yaml>}"

open=0 merged=0 closed=0 error=0

grep 'bandit-fix-pr:' "$PROGRESS" | sed 's/.*bandit-fix-pr: //' | while read -r url; do
  repo=$(echo "$url" | sed 's|https://github.com/||' | cut -d/ -f1-2)
  pr_num=$(basename "$url")
  state=$(gh pr view "$pr_num" --repo "$repo" --json state --jq '.state' 2>&1)

  printf "%-55s %-8s %s\n" "$repo" "#$pr_num" "$state"
done

echo ""
echo "=== SUMMARY ==="
grep 'bandit-fix-pr:' "$PROGRESS" | sed 's/.*bandit-fix-pr: //' | while read -r url; do
  repo=$(echo "$url" | sed 's|https://github.com/||' | cut -d/ -f1-2)
  pr_num=$(basename "$url")
  gh pr view "$pr_num" --repo "$repo" --json state --jq '.state' 2>&1
done | sort | uniq -c | sort -rn
