#!/usr/bin/env bash
# pin-actions.sh — Pin all GitHub Actions to full commit SHAs
#
# Usage:
#   ./pin-actions.sh <repo-path> [--dry-run]
#
# Example:
#   ./pin-actions.sh /path/to/k8sd
#   ./pin-actions.sh /path/to/k8sd --dry-run

set -euo pipefail

REPO_PATH="${1:?Usage: $0 <repo-path> [--dry-run]}"
DRY_RUN="${2:-}"

if [[ ! -d "$REPO_PATH/.github" ]]; then
  echo "Error: $REPO_PATH does not look like a GitHub repo (no .github dir)"
  exit 1
fi

# Find all workflow and composite action YAML files
YAML_FILES=$(find "$REPO_PATH/.github" -name '*.yaml' -o -name '*.yml' | sort)

if [[ -z "$YAML_FILES" ]]; then
  echo "No workflow files found in $REPO_PATH/.github"
  exit 0
fi

echo "=== Pin GitHub Actions to SHA ==="
echo "Repo: $REPO_PATH"
echo ""

# Cache for resolved SHAs: action@tag -> sha
declare -A SHA_CACHE

resolve_sha() {
  local action="$1"
  local tag="$2"
  local cache_key="${action}@${tag}"

  if [[ -n "${SHA_CACHE[$cache_key]:-}" ]]; then
    echo "${SHA_CACHE[$cache_key]}"
    return
  fi

  local repo_url="https://github.com/${action}"
  # Try to resolve the tag to a SHA via git ls-remote
  local sha
  sha=$(git ls-remote --tags --refs "$repo_url" "refs/tags/${tag}" 2>/dev/null | awk '{print $1}' | head -1)

  # If not found as a tag, try as a branch
  if [[ -z "$sha" ]]; then
    sha=$(git ls-remote --heads "$repo_url" "refs/heads/${tag}" 2>/dev/null | awk '{print $1}' | head -1)
  fi

  # Some tags are annotated — dereference them
  if [[ -z "$sha" ]]; then
    sha=$(git ls-remote "$repo_url" "refs/tags/${tag}^{}" 2>/dev/null | awk '{print $1}' | head -1)
  fi

  if [[ -n "$sha" ]]; then
    SHA_CACHE[$cache_key]="$sha"
    echo "$sha"
  fi
}

TOTAL=0
PINNED=0
SKIPPED=0
FAILED=0

for file in $YAML_FILES; do
  rel_path="${file#$REPO_PATH/}"
  file_changed=false

  # Find lines with "uses:" that reference actions with a tag (not already a SHA)
  # Match: uses: owner/action@tag  (where tag is NOT a 40-char hex SHA)
  while IFS= read -r match; do
    [[ -z "$match" ]] && continue

    # Extract the full action reference (e.g. "actions/checkout@v4")
    action_ref=$(echo "$match" | grep -oP 'uses:\s*\K[^\s#]+' || true)
    [[ -z "$action_ref" ]] && continue

    # Split into action and tag
    action=$(echo "$action_ref" | cut -d'@' -f1)
    tag=$(echo "$action_ref" | cut -d'@' -f2)

    # Skip if tag is already a full SHA (40 hex chars)
    if [[ "$tag" =~ ^[0-9a-f]{40}$ ]]; then
      ((SKIPPED++)) || true
      continue
    fi

    # Skip local/composite actions (start with ./)
    if [[ "$action" == ./* ]]; then
      ((SKIPPED++)) || true
      continue
    fi

    ((TOTAL++)) || true

    echo -n "  $rel_path: $action@$tag -> "

    sha=$(resolve_sha "$action" "$tag")

    if [[ -z "$sha" ]]; then
      echo "FAILED (could not resolve SHA)"
      ((FAILED++)) || true
      continue
    fi

    echo "${sha} # ${tag}"
    ((PINNED++)) || true

    if [[ "$DRY_RUN" != "--dry-run" ]]; then
      # Escape special chars for sed
      old_escaped=$(printf '%s\n' "$action_ref" | sed 's/[&/\]/\\&/g; s/\./\\./g')
      new_escaped=$(printf '%s\n' "${action}@${sha} # ${tag}" | sed 's/[&/\]/\\&/g')

      # Replace in file — match "uses: action@tag" with optional trailing comment
      # This handles both "uses: action@tag" and "uses: action@tag # old comment"
      if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s|uses: *${old_escaped}\( *#.*\)\{0,1\}$|uses: ${action}@${sha} # ${tag}|g" "$file"
      else
        sed -i "s|uses: *${old_escaped}\( *#.*\)\{0,1\}$|uses: ${action}@${sha} # ${tag}|g" "$file"
      fi
      file_changed=true
    fi

  done < <(grep -n 'uses:' "$file" 2>/dev/null || true)

done

echo ""
echo "=== Summary ==="
echo "Actions found:   $TOTAL"
echo "Pinned to SHA:   $PINNED"
echo "Already pinned:  $SKIPPED"
echo "Failed:          $FAILED"

if [[ "$DRY_RUN" == "--dry-run" ]]; then
  echo ""
  echo "(dry-run mode — no files were modified)"
fi
