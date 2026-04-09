#!/bin/bash
# push-and-create-prs.sh — Push SAST branches and create PRs for processed repos
#
# Usage:
#   bash push-and-create-prs.sh <results-file> <clone-dir> <pr-output-file>
#
# results-file:   output from process-repos.sh (lines like OK:org/repo:branch)
# clone-dir:      directory containing the repo clones
# pr-output-file: where to write PR URLs

set -euo pipefail

export GH_PAGER=cat
export GIT_TERMINAL_PROMPT=0

RESULTS_FILE="${1:?Usage: push-and-create-prs.sh <results-file> <clone-dir> <pr-output-file>}"
BASE_DIR="${2:?}"
PR_FILE="${3:?}"

> "$PR_FILE"

PYTHON_TITLE="ci: add SAST workflows (semgrep + bandit) with dep-pinned installs"
PYTHON_BODY="## Summary

Add static application security testing (SAST) workflows with hash-pinned pip dependencies, per the security team's recommendation that every repository implement SAST scanning.

## Changes

### Semgrep SAST workflow (\`.github/workflows/semgrep.yaml\`)
- Runs \`p/python\` and \`p/github-actions\` rulesets on push/PR
- Advisory-only: results uploaded to GitHub Security tab via SARIF

### Bandit security scan (\`.github/workflows/bandit.yaml\`)
- Scans Python code for common security anti-patterns
- Blocks on HIGH severity only (\`-lll\` flag)
- Runs on push/PR and weekly (Monday 09:00 UTC)

### Dependency pinning (\`ci/requirements-*.{in,txt}\`)
- Pin \`semgrep\` and \`bandit\` pip installs with hash verification
- Satisfies OSSF Scorecard **Pinned-Dependencies** checks for pip

## Reference
- Semgrep: https://github.com/canonical/k8s-snap/pull/2468
- Bandit: https://github.com/canonical/k8s-snap/pull/2466
- Dep pinning: https://github.com/canonical/k8s-snap/pull/2492"

NONPYTHON_TITLE="ci: add Semgrep SAST workflow with dep-pinned install"
NONPYTHON_BODY="## Summary

Add Semgrep SAST workflow with hash-pinned pip dependency, per the security team's recommendation that every repository implement SAST scanning.

Bandit is not included as this repository has no Python code.

## Changes

### Semgrep SAST workflow (\`.github/workflows/semgrep.yaml\`)
- Runs \`p/python\` and \`p/github-actions\` rulesets on push/PR
- Advisory-only: results uploaded to GitHub Security tab via SARIF

### Dependency pinning (\`ci/requirements-semgrep.{in,txt}\`)
- Pin \`semgrep\` pip install with hash verification
- Satisfies OSSF Scorecard **Pinned-Dependencies** checks for pip

## Reference
- Semgrep: https://github.com/canonical/k8s-snap/pull/2468
- Dep pinning: https://github.com/canonical/k8s-snap/pull/2492"

while IFS=: read st org_repo branch; do
  [[ "$st" != "OK" ]] && continue

  org=$(echo "$org_repo" | cut -d/ -f1)
  repo=$(echo "$org_repo" | cut -d/ -f2)

  if [[ "$org" == "charmed-kubernetes" && "$repo" == ".github" ]]; then
    dir="$BASE_DIR/.github"
  else
    dir="$BASE_DIR/$repo"
  fi

  cd "$dir" || { echo "FAIL:no-dir:$org_repo" | tee -a "$PR_FILE"; continue; }

  git checkout KU-5612/sast-workflows 2>/dev/null || { echo "FAIL:no-branch:$org_repo" | tee -a "$PR_FILE"; continue; }

  # Determine base branch
  base_branch=$(git rev-parse --abbrev-ref HEAD@{upstream} 2>/dev/null | sed 's|origin/||')
  if [[ -z "$base_branch" ]]; then
    if git show-ref --verify --quiet refs/remotes/origin/main; then
      base_branch="main"
    elif git show-ref --verify --quiet refs/remotes/origin/master; then
      base_branch="master"
    elif git show-ref --verify --quiet refs/remotes/origin/develop; then
      base_branch="develop"
    else
      base_branch="main"
    fi
  fi

  echo "Pushing $org_repo..."
  git push origin KU-5612/sast-workflows 2>&1 | tail -1

  if [[ -f ".github/workflows/bandit.yaml" ]]; then
    title="$PYTHON_TITLE"
    body="$PYTHON_BODY"
  else
    title="$NONPYTHON_TITLE"
    body="$NONPYTHON_BODY"
  fi

  PR_URL=$(gh pr create \
    --repo "$org_repo" \
    --base "$base_branch" \
    --head KU-5612/sast-workflows \
    --title "$title" \
    --body "$body" 2>&1 | grep "https://github.com")

  if [[ -n "$PR_URL" ]]; then
    echo "PR:$org_repo:$PR_URL" | tee -a "$PR_FILE"
  else
    echo "FAIL:pr-create:$org_repo" | tee -a "$PR_FILE"
  fi

  sleep 1  # Rate limit
done < "$RESULTS_FILE"

echo ""
echo "=== PR SUMMARY ==="
echo "Created: $(grep '^PR:' "$PR_FILE" | wc -l | tr -d ' ')"
echo "Failed: $(grep '^FAIL:' "$PR_FILE" | wc -l | tr -d ' ')"
