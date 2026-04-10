---
description: "End-to-end workflow: read a Jira ticket, plan, implement, review, test, and ship"
---

# Work on Ticket — Full Development Workflow

Take a Jira ticket from backlog to done. Orchestrate planning, implementation, review, testing, and CI — fixing issues along the way.

**Important constraints:**

- The user signs all commits — present `git commit -S -m "..."` commands for them to run
- Use `GIT_TERMINAL_PROMPT=0` on all git network commands
- Ask for user approval at every gate (marked with 🚦) before proceeding
- If context is getting long, checkpoint state so `/resume-session` can continue

## Workflow

### Step 1 — Read and understand the ticket

1. Fetch the Jira ticket via Atlassian MCP (`cloudId: warthogs.atlassian.net`)
2. Extract: summary, description, acceptance criteria, linked issues, epic context
3. Identify the target repo(s) and branch naming: `KU-XXXX/<description>`
4. Transition the ticket to **In Progress**

### Step 2 — Explore the codebase

Before planning, understand what you're working with:

1. Clone the target repo (or navigate to it if already local)
2. Read relevant files: the area of code the ticket touches, existing tests, CI config
3. Check for contributing guidelines, code style configs, existing patterns
4. Note the primary language, test framework, linter, and build system

### Step 3 — Plan the approach

Think like a senior architect. Produce a brief plan:

- **Context** — what exists today
- **Approach** — what to change and why
- **Files to modify** — list of files and what changes in each
- **Risks** — what could go wrong
- **Estimated complexity** — trivial / small / medium

🚦 **Gate: Present the plan to the user.** Wait for approval before coding. If the plan reveals the ticket is underspecified, ask the user to clarify.

### Step 4 — Implement

Think like a senior developer:

1. Create a feature branch: `KU-XXXX/<description>`
2. Make the changes following existing codebase patterns
3. Keep diffs minimal — only change what's needed
4. Conventional commits: `feat:`, `fix:`, `ci:`, `docs:`, `refactor:`, `test:`
5. Add or update tests for new behavior
6. Save any scripts used to the project's `scripts/` directory

**Commit signing:** Stage changes yourself, then tell the user:

> Run: `cd <repo> && git commit -S -m "<message>"`

Never commit directly — always hand off to the user.

### Step 5 — Self-review

Review your own diff like a skeptical reviewer. Check:

- [ ] All acceptance criteria from the ticket are satisfied
- [ ] No unvalidated inputs at system boundaries
- [ ] No missing error handling on I/O operations
- [ ] No hardcoded secrets or credentials
- [ ] No shell injection in CI workflows (`${{ github.event.* }}` in `run:`)
- [ ] No race conditions or resource leaks
- [ ] No breaking API changes without version bumps
- [ ] Diff is minimal — no unrelated changes

Fix any blockers before proceeding. Report warnings to the user.

### Step 6 — Lint and test

Run the project's linter and test suite:

| Language | Lint / Format                 | Test              |
| -------- | ----------------------------- | ----------------- |
| Go       | `gofmt`, `golangci-lint run`  | `go test ./...`   |
| Python   | `black --check`, `ruff check` | `pytest` or `tox` |
| Shell    | `shellcheck`                  | —                 |
| YAML     | `yamllint`                    | —                 |

Check `Makefile`, `tox.ini`, `pyproject.toml` for the repo's actual commands.

**Bail-out rule:** If you've made 3 attempts to fix a test/lint failure and it's still failing, stop and report to the user with what you've tried. Don't loop indefinitely.

For pre-existing failures (not caused by your change): note them, don't fix in this PR, mention in PR description.

🚦 **Gate: Show the user the diff and test results.** Ask: "Tests pass, diff looks good — ready to push?"

### Step 7 — Push and create PR

1. Push: `GIT_TERMINAL_PROMPT=0 git push origin KU-XXXX/<description>`
2. Draft the PR title and body, then show it to the user:

🚦 **Gate: Present PR title and body.** Ask: "Shall I create this PR and request a reviewer?"

3. Create PR via GitHub MCP:
   - Title: conventional commit style
   - Body: summary, acceptance criteria checklist (no Jira ticket keys or Jira links)
   - Request reviewer from the team:
     - `bschimke95` — general reviews, AI-generated code
     - `berkayoz` — networking, MicroK8s
     - `HomayoonAlimohammadi` — general k8s, CAPI
     - `mateoflorido` — Charmed Kubernetes
4. Comment the PR URL on the Jira ticket

### Step 8 — Monitor CI

1. Check CI status after a short wait
2. If checks fail:
   - Read the failure logs
   - **Your change caused it**: fix, push, re-check (max 3 attempts)
   - **Pre-existing / flaky**: note in PR description, retry once
   - **Out-of-scope fix needed**: create a separate branch/PR
3. If CI is still failing after 3 fix attempts, report to user and stop

### Step 9 — Update Jira

1. Transition the ticket to **In Review**
2. Add a comment with: PR link, brief summary, any notes for the reviewer

🚦 **Gate: Ask user before transitioning Jira status.**

### Step 10 — Report

```
## Done: <summary>

PR: <url>
Branch: KU-XXXX/<description>
CI: ✅ passing | ⚠️ pre-existing failures noted | ❌ needs attention
Reviewer: @<handle>

Changes:
- <bullet summary>

Acceptance criteria:
- [x] <criterion 1>
- [x] <criterion 2>
```

## Checkpointing

If the conversation is getting long (many tool calls, large diffs), save a checkpoint:

1. Write current state to a comment: what step you're on, what's done, what's next
2. Include: repo path, branch name, ticket key, files changed, test status
3. The user can resume with `/resume-session` in a new conversation

## Error handling

- **Clone fails (403)**: report missing permissions, stop
- **Tests fail 3 times**: report what you tried, stop and ask the user
- **CI flaky**: retry once, then note as flaky in PR description
- **Ticket is vague**: ask before coding, don't guess requirements
- **Change grows beyond scope**: stop, ask user whether to expand or split
- **Context getting long**: checkpoint and suggest continuing in a new session

## Tips

- For CI-only changes, focus on security and devops checklists over general review
- For Go repos, always run `go mod tidy` after dependency changes
- For Python repos, check `requirements.txt` or `pyproject.toml` for needed updates
- User signs all commits — never run `git commit` directly
