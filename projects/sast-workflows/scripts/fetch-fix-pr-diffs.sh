#!/bin/bash
# fetch-fix-pr-diffs.sh — Fetch and display diffs for all bandit fix PRs
#
# Usage:
#   bash fetch-fix-pr-diffs.sh <progress-yaml> [output-file]
#
# Reads bandit-fix-pr URLs from PROGRESS.yaml and fetches each PR's full diff.
# Optionally writes to output-file (otherwise prints to stdout).

set -euo pipefail

export GH_PAGER=cat

PROGRESS="${1:?Usage: fetch-fix-pr-diffs.sh <progress-yaml> [output-file]}"
OUTPUT="${2:-}"

if [[ -n "$OUTPUT" ]]; then
  exec > "$OUTPUT"
fi

grep 'bandit-fix-pr:' "$PROGRESS" | sed 's/.*bandit-fix-pr: //' | while read -r url; do
  repo=$(echo "$url" | sed 's|https://github.com/||' | cut -d/ -f1-2)
  pr_num=$(basename "$url")

  echo "================================================================"
  echo "PR: $url"
  echo "REPO: $repo  PR#: $pr_num"
  echo "----------------------------------------------------------------"

  gh pr diff "$pr_num" --repo "$repo" 2>&1

  echo ""
  echo "================================================================"
  echo ""
done

echo "=== Done: $(grep -c 'bandit-fix-pr:' "$PROGRESS") PRs fetched ==="
