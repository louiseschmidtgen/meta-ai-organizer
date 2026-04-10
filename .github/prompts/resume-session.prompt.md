---
description: "Resume an interrupted multi-repo campaign in a new conversation"
---

# Resume Session — Continue a Multi-Repo Campaign

## Purpose

Resume an interrupted multi-repo campaign in a new conversation by restoring context from the progress tracker and project artifacts.

## Prompt

```
I'm resuming the "{{CAMPAIGN_NAME}}" campaign. Here's the context:

**Project directory:** {{PROJECT_DIR}}
**Progress file:** {{PROGRESS_FILE}}
**Script:** {{SCRIPT_PATH}}
**Branch name:** {{BRANCH_NAME}}
**Commit message:** {{COMMIT_MESSAGE}}

**Please:**
1. Read the progress file to see what's been completed.
2. Count repos by status and print a summary.
3. Identify the next org/batch to process.
4. List the next {{BATCH_SIZE}} repos to work on.
5. Proceed with the batch processing workflow.

**Workflow per repo:**
Clone → run script → apply manual fixups → branch → stage → user signs commit → push → create PR → update tracker

**Key conventions:**
- I sign all commits (give me `git commit -S` commands)
- Use `GIT_TERMINAL_PROMPT=0` on all git network commands
- Use `timeout {{SCRIPT_TIMEOUT}}` on the script
- Mark 403 repos as `missing-permissions`
- Print a summary table after each batch

**Additional context:**
{{ADDITIONAL_CONTEXT}}
```

## Variables

| Variable                 | Description                                               | Example                                              |
| ------------------------ | --------------------------------------------------------- | ---------------------------------------------------- |
| `{{CAMPAIGN_NAME}}`      | Campaign name                                             | `Pin Actions to SHA`                                 |
| `{{PROJECT_DIR}}`        | Root directory of the project                             | `projects/pin-actions-to-sha/`                       |
| `{{PROGRESS_FILE}}`      | Path to PROGRESS.yaml                                     | `projects/pin-actions-to-sha/PROGRESS.yaml`          |
| `{{SCRIPT_PATH}}`        | Path to the transformation script                         | `projects/pin-actions-to-sha/scripts/pin-actions.sh` |
| `{{BRANCH_NAME}}`        | Branch name for PRs                                       | `KU-5612/pin-actions-to-sha`                         |
| `{{COMMIT_MESSAGE}}`     | Commit message                                            | `ci: pin GitHub Actions to commit SHAs`              |
| `{{BATCH_SIZE}}`         | Repos per batch                                           | `10`                                                 |
| `{{SCRIPT_TIMEOUT}}`     | Timeout for the script in seconds                         | `60`                                                 |
| `{{ADDITIONAL_CONTEXT}}` | Project-specific notes (SHA caches, fixup patterns, etc.) | See project context dir                              |
