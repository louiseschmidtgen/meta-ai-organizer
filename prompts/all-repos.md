# Multi-Repo Campaign — Prompt Library

Generic, reusable prompts for running any scripted change across many GitHub repositories in batches.

## Prompts

| Prompt                                       | Purpose                                                     |
| -------------------------------------------- | ----------------------------------------------------------- |
| [enumerate-repos.md](enumerate-repos.md)     | List repos in an org, filter exclusions, group into batches |
| [batch-processing.md](batch-processing.md)   | Process a batch end-to-end (clone → script → PR → track)    |
| [progress-tracking.md](progress-tracking.md) | PROGRESS.yaml structure and status codes                    |
| [resume-session.md](resume-session.md)       | Resume an interrupted campaign in a new conversation        |

## Workflow

1. **Enumerate** — list repos in the target org
2. **Batch** — process 5–10 repos at a time
3. **Track** — update PROGRESS.yaml after each repo
4. **Resume** — pick up where you left off in a new session

Project-specific fixups and caches live in each project's own `context/` directory
(e.g. `projects/pin-actions-to-sha/context/sha-cache.md`).

## Using These Prompts for a New Campaign

1. Create a project directory under `projects/` with `scripts/`, `context/`, and a `PROGRESS.yaml`.
2. Fill in the `{{variables}}` in each prompt with your campaign's values.
3. Follow the workflow order above.

### Example variable set for a campaign

```yaml
CAMPAIGN_NAME: "Pin Actions to SHA"
ORG: canonical
SCRIPT_PATH: projects/pin-actions-to-sha/scripts/pin-actions.sh
SCRIPT_TIMEOUT: 60
BRANCH_NAME: KU-5612/pin-actions-to-sha
COMMIT_MESSAGE: "ci: pin GitHub Actions to commit SHAs"
STAGE_PATHS: .github/
PR_TITLE: "ci: pin GitHub Actions to commit SHAs"
PR_BODY: |
  Pin all GitHub Actions to their commit SHAs to improve supply chain security.

  This prevents:
  - Compromised tags from injecting malicious code
  - Unexpected behavior from mutable references
  - Supply chain attacks via action tag manipulation
PROGRESS_FILE: projects/pin-actions-to-sha/PROGRESS.yaml
PROJECT_CONTEXT_DIR: projects/pin-actions-to-sha/context/
BATCH_SIZE: 10
EXCLUDE_PATTERNS: "mx-"
```

