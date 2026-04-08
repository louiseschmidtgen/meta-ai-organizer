#!/usr/bin/env bash
# pin-actions.sh — Pin all GitHub Actions to full commit SHAs
# Fixed for macOS (BSD grep compatibility)

set -euo pipefail

REPO_PATH="${1:?Usage: $0 <repo-path>}"

if [[ ! -d "$REPO_PATH/.github" ]]; then
  echo "Error: $REPO_PATH does not look like a GitHub repo (no .github dir)"
  exit 1
fi

# Find all workflow and composite action YAML files
YAML_FILES=$(find "$REPO_PATH/.github" -type f \( -name '*.yaml' -o -name '*.yml' \) | sort)

if [[ -z "$YAML_FILES" ]]; then
  echo "No workflow files found in $REPO_PATH/.github"
  exit 0
fi

echo "=== Pin GitHub Actions to SHA ==="
echo "Repo: $REPO_PATH"
echo ""

# Cache for resolved SHAs
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
ALREADY_PINNED=0
SKIPPED=0
FAILED=0

for file in $YAML_FILES; do
  rel_path="${file#$REPO_PATH/}"
  file_changed=false

  # Process each line with "uses:"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ ! "$line" =~ uses: ]] && continue

    # Extract action reference (handle both quoted and unquoted)
    action_ref=$(echo "$line" | sed -E 's/.*uses:[[:space:]]*["'"'"']?([^[:space:]#"'"'"']+).*/\1/')
    
    # Skip if no ref found
    if [[ -z "$action_ref" ]] || [[ "$action_ref" == "$line" ]]; then
      continue
    fi

    # Skip if no @ symbol (malformed)
    if [[ ! "$action_ref" =~ "@" ]]; then
      continue
    fi

    # Extract action and tag
    action=$(echo "$action_ref" | cut -d'@' -f1)
    tag=$(echo "$action_ref" | cut -d'@' -f2)

    ((TOTAL++)) || true

    # Skip if tag is already a full SHA (40 hex chars)
    if [[ "$tag" =~ ^[0-9a-fA-F]{40}$ ]]; then
      ((ALREADY_PINNED++)) || true
      continue
    fi

    # Skip local/composite actions
    if [[ "$action" == ./* ]]; then
      ((SKIPPED++)) || true
      continue
    fi

    echo "  Resolving $action_ref..."
    sha=$(resolve_sha "$action" "$tag")

    if [[ -z "$sha" ]]; then
      echo "    ⚠ Failed to resolve SHA"
      ((FAILED++)) || true
      continue
    fi

    # Build the replacement string with comment
    new_ref="$action@$sha # $tag"
    
    # Escape special chars for sed
    old_escaped=$(printf '%s\n' "$action_ref" | sed -e 's/[\/&]/\\&/g')
    new_escaped=$(printf '%s\n' "$new_ref" | sed -e 's/[\/&]/\\&/g')
    
    # Replace in file
    sed -i.bak "s/$old_escaped/$new_escaped/g" "$file"
    rm -f "$file.bak"
    
    echo "    ✓ Pinned to $sha"
    ((PINNED++)) || true
    file_changed=true
  done < "$file"

  if [[ "$file_changed" == true ]]; then
    echo "  → $rel_path modified"
  fi
done

echo ""
echo "=== Summary ==="
echo "Total actions found:  $TOTAL"
echo "Pinned to SHA:        $PINNED"
echo "Already pinned:       $ALREADY_PINNED"
echo "Skipped (local):      $SKIPPED"
echo "Failed:               $FAILED"
