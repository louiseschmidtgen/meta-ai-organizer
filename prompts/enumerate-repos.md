# Enumerate Repos in a GitHub Org

## Purpose

List all public non-archived repositories in a GitHub organization, apply exclusion filters, and group the results into batches for processing.

## Model / Agent

GitHub Copilot (Claude) in VS Code — uses GitHub MCP tools.

## Prompt

```
List all public repositories in the {{ORG}} GitHub organization for the "{{CAMPAIGN_NAME}}" campaign.

**Steps:**
1. Paginate through all repos in {{ORG}} using the GitHub API.
2. Filter OUT:
   - Archived repos → log as `archived` in the progress file
   - Private / internal repos → skip silently
   - Repos matching any exclusion pattern in {{EXCLUDE_PATTERNS}} → skip silently
3. Sort the remaining repos alphabetically.
4. Cross-reference with the progress file at {{PROGRESS_FILE}} to identify already-processed repos.
5. Output the remaining `todo` repos grouped into batches of {{BATCH_SIZE}}.

**Output format:**
```
=== {{ORG}} — Repos to Process ===
Total public: X | Archived: Y | Excluded: Z | Already done: W | Remaining: R

Batch 1: repo-a, repo-b, repo-c, ...
Batch 2: repo-d, repo-e, repo-f, ...
```
```

## Variables

| Variable               | Description                                  | Example                             |
| ---------------------- | -------------------------------------------- | ----------------------------------- |
| `{{ORG}}`              | GitHub organization                          | `canonical`                         |
| `{{CAMPAIGN_NAME}}`    | Name of the campaign being run               | `Pin Actions to SHA`                |
| `{{EXCLUDE_PATTERNS}}` | Comma-separated prefixes or patterns to skip | `mx-, test-`                        |
| `{{BATCH_SIZE}}`       | Repos per batch                              | `10`                                |
| `{{PROGRESS_FILE}}`    | Path to progress tracker                     | `projects/my-project/PROGRESS.yaml` |

## Example Output

```
=== canonical — Repos to Process ===
Total public: 97 | Archived: 12 | Excluded: 3 | Already done: 40 | Remaining: 42

Batch 1: cdk-addons, cdk-shrinkwrap, charm-aws-integrator, ...
Batch 2: charm-azure-integrator, charm-calico, charm-canal, ...
```

## Changelog

- 2026-04-08 — Generalised from pin-actions-specific version
- 2025-07-24 — Initial version
