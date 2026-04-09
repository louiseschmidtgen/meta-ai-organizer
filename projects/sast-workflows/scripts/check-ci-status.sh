#!/bin/bash
# check-ci-status.sh — Check semgrep and bandit CI results for a batch of PRs
#
# Usage:
#   bash check-ci-status.sh <prs-file>
#
# prs-file: output from push-and-create-prs.sh (lines like PR:org/repo:url)

set -euo pipefail

export GH_PAGER=cat

PR_FILE="${1:?Usage: check-ci-status.sh <prs-file>}"

check_workflow() {
  local name="$1"
  local checks="$2"
  local line
  line=$(echo "$checks" | grep -i "$name")
  if [[ -z "$line" ]]; then
    echo "N/A"
  elif echo "$line" | grep -q "pass"; then
    echo "PASS"
  elif echo "$line" | grep -q "fail"; then
    echo "FAIL"
  elif echo "$line" | grep -q "pending"; then
    echo "PEND"
  else
    echo "OTHER"
  fi
}

echo "=== CI STATUS ==="
printf "%-50s %-8s %-8s\n" "REPO" "SEMGREP" "BANDIT"
printf "%-50s %-8s %-8s\n" "----" "-------" "------"

semgrep_pass=0 semgrep_fail=0
bandit_pass=0 bandit_fail=0 bandit_na=0

while IFS=: read st org_repo url; do
  [[ "$st" != "PR" ]] && continue
  pr_num=$(basename "$url")
  checks=$(gh pr checks "$pr_num" --repo "$org_repo" 2>&1)

  s=$(check_workflow "semgrep" "$checks")
  b=$(check_workflow "bandit" "$checks")

  printf "%-50s %-8s %-8s\n" "$org_repo" "$s" "$b"

  [[ "$s" == "PASS" ]] && semgrep_pass=$((semgrep_pass+1))
  [[ "$s" == "FAIL" ]] && semgrep_fail=$((semgrep_fail+1))
  [[ "$b" == "PASS" ]] && bandit_pass=$((bandit_pass+1))
  [[ "$b" == "FAIL" ]] && bandit_fail=$((bandit_fail+1))
  [[ "$b" == "N/A" ]] && bandit_na=$((bandit_na+1))
done < "$PR_FILE"

echo ""
echo "=== SUMMARY ==="
echo "Semgrep: $semgrep_pass pass, $semgrep_fail fail"
echo "Bandit:  $bandit_pass pass, $bandit_fail fail, $bandit_na N/A"

# List failed bandit repos for fix script
if [[ $bandit_fail -gt 0 ]]; then
  echo ""
  echo "=== BANDIT FAILURES (need fix PRs) ==="
  while IFS=: read st org_repo url; do
    [[ "$st" != "PR" ]] && continue
    pr_num=$(basename "$url")
    checks=$(gh pr checks "$pr_num" --repo "$org_repo" 2>&1)
    b=$(check_workflow "bandit" "$checks")
    [[ "$b" == "FAIL" ]] && echo "$org_repo"
  done < "$PR_FILE"
fi
