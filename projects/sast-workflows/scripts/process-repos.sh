#!/bin/bash
# process-repos.sh — Add SAST workflows (semgrep + bandit) to a batch of repos
#
# Usage:
#   bash process-repos.sh <repo-list.txt> <clone-dir> <results-file>
#
# repo-list.txt: one repo per line, e.g. "canonical/microk8s"
# clone-dir:     directory containing shallow clones of repos
# results-file:  output file for processing results
#
# Requires: templates at ../templates/ relative to this script

set -euo pipefail

REPO_LIST="${1:?Usage: process-repos.sh <repo-list.txt> <clone-dir> <results-file>}"
BASE="${2:?}"
RESULTS="${3:?}"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATES="$SCRIPT_DIR/templates"
PROGRESS="$SCRIPT_DIR/PROGRESS.yaml"

> "$RESULTS"

while IFS= read -r repo; do
  name=$(basename "$repo")
  dir="$BASE/$name"

  # Determine if Python
  bandit=$(grep -A3 "repo: ${repo}$" "$PROGRESS" | grep "bandit:" | head -1 | sed 's/.*bandit: //')
  [[ "$bandit" == "not-applicable" ]] && is_python="no" || is_python="yes"

  # Check dir exists
  if [[ ! -d "$dir" ]]; then
    echo "SKIP:no-dir:$repo" | tee -a "$RESULTS"
    continue
  fi

  cd "$dir" || continue

  DEFAULT_BRANCH=$(git branch --show-current)

  # Already processed?
  if git branch --list KU-5612/sast-workflows 2>/dev/null | grep -q .; then
    echo "OK:$repo:$DEFAULT_BRANCH" | tee -a "$RESULTS"
    continue
  fi

  # No .github dir?
  if [[ ! -d ".github" ]]; then
    echo "SKIP:no-github-dir:$repo" | tee -a "$RESULTS"
    continue
  fi

  # Create branch
  git checkout -b KU-5612/sast-workflows 2>/dev/null

  mkdir -p .github/workflows

  # Check if semgrep already exists
  if [[ -f ".github/workflows/semgrep.yaml" ]] || [[ -f ".github/workflows/semgrep.yml" ]]; then
    echo "SKIP:semgrep-exists:$repo" | tee -a "$RESULTS"
    git checkout "$DEFAULT_BRANCH" 2>/dev/null
    git branch -D KU-5612/sast-workflows 2>/dev/null
    continue
  fi

  # Copy semgrep workflow
  cp "$TEMPLATES/workflows/semgrep.yaml" .github/workflows/semgrep.yaml

  # Handle master/develop branches (add as push/PR trigger alongside main)
  if [[ "$DEFAULT_BRANCH" == "master" ]]; then
    sed -i.bak '/            - main/a\
            - master' .github/workflows/semgrep.yaml
    rm -f .github/workflows/semgrep.yaml.bak
  fi
  if [[ "$DEFAULT_BRANCH" == "develop" ]]; then
    sed -i.bak '/            - main/a\
            - develop' .github/workflows/semgrep.yaml
    rm -f .github/workflows/semgrep.yaml.bak
  fi

  mkdir -p ci
  cp "$TEMPLATES/lock-files/requirements-semgrep.in" ci/
  cp "$TEMPLATES/lock-files/requirements-semgrep.txt" ci/

  if [[ "$is_python" == "yes" ]]; then
    cp "$TEMPLATES/workflows/bandit.yaml" .github/workflows/bandit.yaml

    if [[ "$DEFAULT_BRANCH" == "master" ]]; then
      sed -i.bak '/            - main/a\
            - master' .github/workflows/bandit.yaml
      rm -f .github/workflows/bandit.yaml.bak
    fi
    if [[ "$DEFAULT_BRANCH" == "develop" ]]; then
      sed -i.bak '/            - main/a\
            - develop' .github/workflows/bandit.yaml
      rm -f .github/workflows/bandit.yaml.bak
    fi

    cp "$TEMPLATES/lock-files/requirements-bandit.in" ci/
    cp "$TEMPLATES/lock-files/requirements-bandit.txt" ci/

    if [[ -f "pyproject.toml" ]]; then
      if ! grep -q "\[tool.bandit\]" pyproject.toml; then
        printf '\n[tool.bandit]\nexclude_dirs = [".tox", ".venv", "venv"]\n' >> pyproject.toml
      fi
    else
      printf '[tool.bandit]\nexclude_dirs = [".tox", ".venv", "venv"]\n' > pyproject.toml
    fi

    COMMIT_MSG="ci: add SAST workflows (semgrep + bandit) with dep-pinned installs"
  else
    COMMIT_MSG="ci: add SAST workflows (semgrep) with dep-pinned install"
  fi

  git add -A
  git commit --no-gpg-sign -m "$COMMIT_MSG" -q

  echo "OK:$repo:$DEFAULT_BRANCH" | tee -a "$RESULTS"
done < "$REPO_LIST"

echo ""
echo "=== SUMMARY ==="
echo "OK: $(grep -c '^OK:' "$RESULTS")"
echo "SKIP: $(grep -c '^SKIP:' "$RESULTS" || echo 0)"
