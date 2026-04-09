#!/bin/bash
# audit-nosec-annotations.sh — Check all bandit fix PRs for remaining nosec annotations
#
# Usage:
#   bash audit-nosec-annotations.sh <progress-yaml>
#
# Reads bandit-fix-pr URLs from PROGRESS.yaml and fetches each PR's diff
# to list every nosec annotation that was introduced. Use this to verify
# that all annotations are justified.

set -euo pipefail

export GH_PAGER=cat

PROGRESS="${1:?Usage: audit-nosec-annotations.sh <progress-yaml>}"

grep 'bandit-fix-pr:' "$PROGRESS" | sed 's/.*bandit-fix-pr: //' | while read -r url; do
  repo=$(echo "$url" | sed 's|https://github.com/||' | cut -d/ -f1-2)
  pr_num=$(basename "$url")
  diff=$(gh pr diff "$pr_num" --repo "$repo" 2>&1)

  # Find added lines containing nosec (skip diff header lines)
  nosecs=$(echo "$diff" | grep 'nosec' | grep '^[+]' | grep -v '^[+][+][+]')
  if [[ -n "$nosecs" ]]; then
    echo "=== $repo#$pr_num ==="
    echo "$nosecs"
    echo ""
  fi
done

echo "=== DONE ==="
