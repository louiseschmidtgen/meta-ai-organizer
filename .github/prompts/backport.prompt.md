---
description: "Backport a merged PR to release branches using cherry-pick"
---

# Backport — Cherry-Pick to Release Branches

Backport a merged PR's commits to one or more release branches. Produces one PR per target branch.

**Input:** One of:

- A merged PR URL (e.g. `https://github.com/canonical/k8s-snap/pull/2468`)
- A repo name + commit SHA(s) to backport
- A repo name + PR number

## Step 1 — Gather PR metadata

Fetch the original PR details:

```bash
gh pr view <PR_NUMBER> --repo <ORG>/<REPO> --json title,body,number,mergeCommit,commits,baseRefName,headRefName,state
```

**Verify:**

- PR state is `MERGED` — refuse to backport open/closed PRs.
- Extract the merge commit SHA or the list of individual commit SHAs.
- Note the original PR title, body, and number for reference.

## Step 2 — Identify target branches

Look up the repo in `repositories/backports.yaml` to find active release branches.

```yaml
# Example entry:
- repo: canonical/k8s-snap
  default-branch: main
  release-branches:
    - release-1.32
    - release-1.33
    - release-1.34
    - release-1.35
```

**If the user specifies target branches**, use those. Otherwise, offer all release branches listed in the config and ask which ones to backport to.

**Skip** branches older than the PR's base branch where the change clearly doesn't apply (e.g. a feature added in 1.34 doesn't need backporting to 1.32).

## Step 3 — Clone and backport

```bash
# Clone once
GIT_TERMINAL_PROMPT=0 git clone https://github.com/<ORG>/<REPO>.git /tmp/backport/<REPO>
cd /tmp/backport/<REPO>
```

**For each target branch:**

```bash
# Start from the release branch
git checkout <RELEASE_BRANCH>
git pull origin <RELEASE_BRANCH>

# Create backport branch
git checkout -b backport/<ORIGINAL_PR_NUMBER>-to-<RELEASE_BRANCH>

# Cherry-pick the merge commit (prefer -m 1 for merge commits)
git cherry-pick -x <MERGE_COMMIT_SHA> -m 1
```

If the original PR had multiple non-squashed commits, cherry-pick each individually:

```bash
git cherry-pick -x <COMMIT_1> <COMMIT_2> ...
```

The `-x` flag adds a `(cherry picked from commit ...)` reference to the commit message.

### Handling conflicts

If `git cherry-pick` produces conflicts:

1. Run `git diff` and `git status` to understand the conflict.
2. **If trivially resolvable** (context drift, import order, minor offset): resolve it, stage, and continue:
   ```bash
   # After resolving
   git add <resolved-files>
   git cherry-pick --continue
   ```
3. **If the conflict is non-trivial** (major code divergence, missing dependencies):
   - Abort: `git cherry-pick --abort`
   - Report to the user: which branch, which files, what the conflict looks like.
   - Ask whether to skip this branch or attempt a manual fix.

**Bail-out rule:** If a cherry-pick has more than 3 conflicting files, abort and report rather than attempting resolution.

## Step 4 — Commit

Give the user the commit command for signing:

```bash
cd /tmp/backport/<REPO> && git commit -S --amend --no-edit
```

Or if the cherry-pick completed cleanly (commit already created by cherry-pick):

```bash
# Cherry-pick already committed — just push
```

**Do not amend the commit message** unless the user asks. The `-x` annotation is valuable for traceability.

## Step 5 — Push and create PR

```bash
GIT_TERMINAL_PROMPT=0 git push origin backport/<ORIGINAL_PR_NUMBER>-to-<RELEASE_BRANCH>
```

Create the PR via GitHub MCP:

- **Title:** `[Backport <RELEASE_BRANCH>] <Original PR title>`
- **Base:** `<RELEASE_BRANCH>`
- **Body:**

  ```
  Backport of #<ORIGINAL_PR_NUMBER> to `<RELEASE_BRANCH>`.

  **Original PR:** <ORIGINAL_PR_URL>

  <Original PR body — truncated if very long>
  ```

**Do not** put Jira ticket keys in the PR title or body (branch names are the sole exception per repo conventions).

## Step 6 — Repeat for remaining branches

Reset to a clean state before each branch:

```bash
git checkout <NEXT_RELEASE_BRANCH>
git pull origin <NEXT_RELEASE_BRANCH>
git checkout -b backport/<ORIGINAL_PR_NUMBER>-to-<NEXT_RELEASE_BRANCH>
```

## Step 7 — Summary

After all branches are processed, print a summary:

| Target Branch | Status     | PR   | Notes                           |
| ------------- | ---------- | ---- | ------------------------------- |
| release-1.35  | PR created | #123 | Clean cherry-pick               |
| release-1.34  | PR created | #124 | 1 conflict resolved             |
| release-1.33  | Skipped    | —    | Non-trivial conflict in pkg/foo |
| release-1.32  | N/A        | —    | Change not applicable           |

## Key Rules

- Use `GIT_TERMINAL_PROMPT=0` on all git network commands to prevent hangs.
- User signs all commits — give `git commit -S` commands, never commit directly.
- One PR per release branch — never batch multiple branches into one PR.
- Always use `-x` flag on cherry-pick for traceability.
- Never force-push to release branches.
- If the repo is not in `backports.yaml`, ask the user for target branches and suggest adding the repo to the config.
