# Progress Tracking — PROGRESS.yaml

## Purpose

Track every repository processed in a multi-repo campaign using a YAML file with consistent structure and status codes.

## Model / Agent

GitHub Copilot (Claude) in VS Code — maintains the tracker across batches.

## Prompt

```
Maintain a PROGRESS.yaml file at {{PROGRESS_FILE}} to track all repositories processed
in the "{{CAMPAIGN_NAME}}" campaign.

**File structure:**

```yaml
# {{CAMPAIGN_NAME}} — Progress Tracker
branch_name: {{BRANCH_NAME}}
commit_message: "{{COMMIT_MESSAGE}}"
started: {{START_DATE}}

# Custom status definitions (add campaign-specific statuses here)
# status_definitions:
#   custom-status: "Description of what this means"

# Section per batch
batch_{{N}}:
  - repo: {{ORG}}/{{REPO}}
    status: {{STATUS}}
    pr: {{PR_URL}}         # only when status is pr-open
    notes: {{NOTES}}       # optional — only for unusual cases
```

**Standard status codes:**
- `pr-open` — PR created and awaiting review/merge
- `no-changes` — Script ran but produced no diff
- `archived` — Repository is archived
- `missing-permissions` — 403 / no push access
- `skipped` — Skipped for other reasons (private, excluded, etc.)
- `todo` — Not yet processed

Add campaign-specific statuses as needed (e.g. `already-pinned`, `no-workflows`)
and document them in the `status_definitions` block at the top of the file.

**Rules:**
- Update the file after EVERY repo, not at end of batch
- Include PR URL for every `pr-open` entry
- Group repos by batch with a comment header showing the batch range and date
- Keep repos sorted alphabetically within each batch
- Add `notes:` only when there's something unusual to explain
```

## Variables

| Variable             | Description                  | Example                                 |
| -------------------- | ---------------------------- | --------------------------------------- |
| `{{PROGRESS_FILE}}`  | Path to the tracker          | `projects/my-project/PROGRESS.yaml`     |
| `{{CAMPAIGN_NAME}}`  | Human-readable campaign name | `Pin Actions to SHA`                    |
| `{{BRANCH_NAME}}`    | Branch used across all repos | `KU-5612/pin-actions-to-sha`            |
| `{{COMMIT_MESSAGE}}` | Commit message used          | `ci: pin GitHub Actions to commit SHAs` |
| `{{START_DATE}}`     | Campaign start date          | `2026-04-07`                            |
| `{{ORG}}`            | GitHub organization          | `canonical`                             |
| `{{STATUS}}`         | One of the status codes      | `pr-open`                               |

## Example Output

```yaml
# Migrate CI to Reusable Workflows — Progress Tracker
branch_name: JIRA-123/migrate-ci
commit_message: "ci: migrate to org-level reusable workflows"
started: 2026-04-08

status_definitions:
  already-migrated: "Repo already uses reusable workflows"
  no-ci: "Repo has no CI configuration"

batch_1:
  - repo: canonical/calico-rocks
    status: pr-open
    pr: https://github.com/canonical/calico-rocks/pull/42

  - repo: canonical/go-migrator
    status: no-ci

  - repo: canonical/grafana-agent-snap
    status: missing-permissions
    notes: "403 Permission denied"
```

## Changelog

- 2026-04-08 — Generalised with extensible status codes
- 2025-07-24 — Initial version
