#!/bin/bash
# update-progress.sh — Update PROGRESS.yaml with batch results
#
# Usage:
#   bash update-progress.sh <results-file> <prs-file> <fix-prs-file> <clone-dir>
#
# results-file:  output from process-repos.sh (OK:/SKIP: lines)
# prs-file:      output from push-and-create-prs.sh (PR: lines)
# fix-prs-file:  output from fix wrapper script (FIX-PR: lines)
# clone-dir:     directory with repo clones (to check for bandit.yaml)

set -euo pipefail

RESULTS_FILE="${1:?Usage: update-progress.sh <results-file> <prs-file> <fix-prs-file> <clone-dir>}"
PR_FILE="${2:?}"
FIX_PR_FILE="${3:?}"
BASE_DIR="${4:?}"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROGRESS="$SCRIPT_DIR/PROGRESS.yaml"

cp "$PROGRESS" "$PROGRESS.bak"

# 1. Update repos with SAST PRs
while IFS=: read st org_repo url; do
  [[ "$st" != "PR" ]] && continue
  repo_name=$(echo "$org_repo" | cut -d/ -f2)
  org=$(echo "$org_repo" | cut -d/ -f1)

  if [[ "$org" == "charmed-kubernetes" && "$repo_name" == ".github" ]]; then
    dir="$BASE_DIR/.github"
  else
    dir="$BASE_DIR/$repo_name"
  fi

  has_bandit="no"
  [[ -f "$dir/.github/workflows/bandit.yaml" ]] && has_bandit="yes"

  escaped_repo=$(echo "$org_repo" | sed 's/\./\\./g')
  line_num=$(grep -n "repo: $escaped_repo$" "$PROGRESS" | head -1 | cut -d: -f1)
  [[ -z "$line_num" ]] && echo "NOT FOUND: $org_repo" && continue

  sed -i.tmp "$((line_num+1))s/semgrep: todo/semgrep: pr-open/" "$PROGRESS"

  if [[ "$has_bandit" == "yes" ]]; then
    sed -i.tmp "$((line_num+2))s/bandit: todo/bandit: pr-open/" "$PROGRESS"
    dep_line=$((line_num+3))
  else
    dep_line=$((line_num+3))
  fi
  sed -i.tmp "${dep_line}s/dep-pinning: todo/dep-pinning: pr-open/" "$PROGRESS"

  sed -i.tmp "${dep_line}a\\
    pr: $url" "$PROGRESS"

  echo "Updated: $org_repo -> pr-open"
done < "$PR_FILE"

# 2. Update SKIP repos (no-github-dir)
while IFS=: read st reason org_repo; do
  [[ "$st" != "SKIP" ]] && continue
  escaped_repo=$(echo "$org_repo" | sed 's/\./\\./g')
  line_num=$(grep -n "repo: $escaped_repo$" "$PROGRESS" | head -1 | cut -d: -f1)
  [[ -z "$line_num" ]] && echo "NOT FOUND SKIP: $org_repo" && continue

  sed -i.tmp "$((line_num+1))s/semgrep: todo/semgrep: no-github-dir/" "$PROGRESS"
  sed -i.tmp "$((line_num+2))s/bandit: todo/bandit: no-github-dir/" "$PROGRESS"
  sed -i.tmp "$((line_num+2))s/bandit: not-applicable/bandit: no-github-dir/" "$PROGRESS"
  sed -i.tmp "$((line_num+3))s/dep-pinning: todo/dep-pinning: no-github-dir/" "$PROGRESS"

  echo "Updated: $org_repo -> no-github-dir"
done < "$RESULTS_FILE"

# 3. Add bandit-fix-pr URLs
if [[ -f "$FIX_PR_FILE" ]]; then
  while IFS=: read st org_repo url; do
    [[ "$st" != "FIX-PR" ]] && continue
    escaped_repo=$(echo "$org_repo" | sed 's/\./\\./g')
    repo_line=$(grep -n "repo: $escaped_repo$" "$PROGRESS" | head -1 | cut -d: -f1)
    if [[ -n "$repo_line" ]]; then
      pr_line=$(sed -n "$((repo_line+1)),$((repo_line+6))p" "$PROGRESS" | grep -n "pr:" | head -1 | cut -d: -f1)
      if [[ -n "$pr_line" ]]; then
        pr_line=$((repo_line + pr_line))
        sed -i.tmp "${pr_line}a\\
    bandit-fix-pr: $url" "$PROGRESS"
        echo "Added fix-pr: $org_repo"
      fi
    fi
  done < "$FIX_PR_FILE"
fi

rm -f "$PROGRESS.tmp"
echo ""
echo "=== DONE ==="
echo "Remaining todo: $(grep 'semgrep: todo' "$PROGRESS" | wc -l | tr -d ' ')"
echo "Total pr-open: $(grep 'semgrep: pr-open' "$PROGRESS" | wc -l | tr -d ' ')"
echo "Total no-github-dir: $(grep 'semgrep: no-github-dir' "$PROGRESS" | wc -l | tr -d ' ')"
