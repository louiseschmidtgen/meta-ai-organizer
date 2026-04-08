# Batch Processing — Multi-Repo Campaign

## Purpose

Process a batch of GitHub repositories through a repeatable workflow: clone, run a transformation script, branch, commit (user signs), push, create PR, and update the progress tracker.

## Model / Agent

GitHub Copilot (Claude) in VS Code — interactive session with user signing commits.

## Prompt

```
Process the next batch of {{BATCH_SIZE}} repos from {{ORG}} for the "{{CAMPAIGN_NAME}}" campaign.

**Repos to process this batch:**
{{REPO_LIST}}

**For each repo, follow this workflow:**

1. Clone (full clone, not shallow):
   ```
   GIT_TERMINAL_PROMPT=0 git clone https://github.com/{{ORG}}/{{REPO}}.git /tmp/{{REPO}}
   ```

2. Run the transformation script:
   ```
   timeout {{SCRIPT_TIMEOUT}} bash {{SCRIPT_PATH}} /tmp/{{REPO}}
   ```

3. If there are manual fixups the script can't handle, apply them now.
   (See project-specific context in {{PROJECT_CONTEXT_DIR}} for details.)

4. Check the diff:
   ```
   cd /tmp/{{REPO}} && git diff
   ```

5. If no changes were produced, mark the repo with the appropriate skip status and move on.

6. Create branch, stage changes, and give me the commit command:
   ```
   git checkout -b {{BRANCH_NAME}}
   git add {{STAGE_PATHS}}
   ```
   Then tell me to run: `cd /tmp/{{REPO}} && git commit -S -m "{{COMMIT_MESSAGE}}"`

7. After I confirm the commit, push:
   ```
   GIT_TERMINAL_PROMPT=0 git push origin {{BRANCH_NAME}}
   ```

8. Create PR via GitHub MCP:
   - Title: `{{PR_TITLE}}`
   - Body: `{{PR_BODY}}`

9. Update the progress file at {{PROGRESS_FILE}} with the PR link and status.

**After the batch**, print a summary table:
| Repo | Status | PR  |
| ---- | ------ | --- |

**Key rules:**
- Use `GIT_TERMINAL_PROMPT=0` on all git network commands to prevent hangs
- Use `timeout` on the transformation script
- User signs all commits — give `git commit -S` commands, never commit directly
- If a repo returns 403, mark as `missing-permissions` and move on
- If a clone hangs or times out, skip and mark accordingly
- Report back after each batch with a summary table
```

## Variables

| Variable                  | Description                                    | Example                                              |
| ------------------------- | ---------------------------------------------- | ---------------------------------------------------- |
| `{{ORG}}`                 | GitHub organization                            | `canonical`                                          |
| `{{REPO}}`                | Repository name (substituted per repo)         | `k8s-snap`                                           |
| `{{REPO_LIST}}`           | Comma or newline-separated list for this batch | `calico-rocks, cert-manager-rock, ...`               |
| `{{BATCH_SIZE}}`          | Number of repos per batch                      | `10`                                                 |
| `{{CAMPAIGN_NAME}}`       | Human-readable campaign name                   | `Pin Actions to SHA`                                 |
| `{{SCRIPT_PATH}}`         | Path to the transformation script              | `projects/pin-actions-to-sha/scripts/pin-actions.sh` |
| `{{SCRIPT_TIMEOUT}}`      | Timeout in seconds for the script              | `60`                                                 |
| `{{PROJECT_CONTEXT_DIR}}` | Dir with project-specific fixup notes          | `projects/pin-actions-to-sha/context/`               |
| `{{BRANCH_NAME}}`         | Branch name for PRs                            | `KU-5612/pin-actions-to-sha`                         |
| `{{STAGE_PATHS}}`         | Paths to `git add`                             | `.github/`                                           |
| `{{COMMIT_MESSAGE}}`      | Commit message                                 | `ci: pin GitHub Actions to commit SHAs`              |
| `{{PR_TITLE}}`            | Pull request title                             | `ci: pin GitHub Actions to commit SHAs`              |
| `{{PR_BODY}}`             | Pull request description body                  | *(see example below)*                                |
| `{{PROGRESS_FILE}}`       | Path to the progress tracker                   | `projects/pin-actions-to-sha/PROGRESS.yaml`          |

## Example Output

```
=== Batch 3 Summary ===

| Repo               | Status              | PR  |
| ------------------ | ------------------- | --- |
| falco-rocks        | pr-open             | #25 |
| fluent-bit-rock    | pr-open             | #15 |
| go-migrator        | no-changes          | —   |
| grafana-agent-snap | missing-permissions | —   |
| harbor-rocks       | pr-open             | #29 |

Processed: 5 | PRs: 3 | Skipped: 2
```

## Changelog

- 2026-04-08 — Generalised from pin-actions-specific version
- 2025-07-24 — Initial version
