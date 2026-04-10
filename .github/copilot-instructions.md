# Copilot Instructions

## Repository context

This is `meta-ai-organizer` — a meta repository for tracking and automating work carried out by AI agents across Canonical Kubernetes repositories.

## Key directories

- `Repositories/repositories.yaml` — all GitHub repos (machine-readable)
- `projects/` — active projects with context, scripts, and progress tracking
- `.github/prompts/` — all reusable prompts: role definitions (`/reviewer`, `/developer`, etc.) and workflow templates (`/batch-processing`, `/resume-session`, etc.)
- `.github/agents/` — `@`-mentionable agents (thin wrappers → `.github/prompts/`)
- `.github/chat-modes/` — conversation-wide modes (thin wrappers → `.github/prompts/`)
- `scripts/` — standalone automation scripts

## Project structure

Every project under `projects/` must contain:

```
projects/<name>/
  README.md           # project overview, goals, Jira ticket
  PROGRESS.yaml       # per-repo status tracking
  CHANGELOG.md        # dated log of significant actions, PRs, decisions
  SUMMARY.md          # high-level project summary (updated at milestones)
  context/            # reference docs, security policies, codebase notes
  scripts/            # ALL scripts used during the project
```

### Script persistence rule

**Every script the LLM generates or uses must be saved in the project's `scripts/` directory.** This includes one-off transformation scripts, batch helpers, analysis tools, and fixup scripts — regardless of language (bash, Python, Go, R, C++, etc.). Scripts must be committed, not left in `/tmp/`.

### CHANGELOG.md format

```markdown
# Changelog

## 2026-04-10

- Created PRs for batch 1 (canonical org): k8s-snap, k8sd, k8s-operator
- Fixed Bandit findings in microk8s (#5453)

## 2026-04-08

- Project kickoff, initial script development
```

### SUMMARY.md format

A brief overview kept current at project milestones: what the project does, current status, key metrics (repos processed, PRs open/merged), and lessons learned.

## Conventions

- Commit messages use [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `ci:`, `docs:`, `refactor:`, `test:`
- Branch names include Jira ticket prefix: `KU-XXXX/description`
- Progress is tracked in YAML files (`PROGRESS.yaml`) per project
- Scripts are saved in the project's `scripts/` directory and should be idempotent and safe to re-run

## Available integrations

- **GitHub MCP** — create PRs, search code, manage issues
- **Atlassian MCP** — Jira issues (cloud ID: `warthogs.atlassian.net`, project: `KU`)
- **Custom agents** — `@reviewer`, `@architect`, `@developer`, `@devops`, `@security`

## Team context (for code reviews)

When using `@reviewer` or requesting reviews, prefer these reviewers from `canonical/kubernetes`:

| GitHub handle          | Expertise                   | When to ask                        |
| ---------------------- | --------------------------- | ---------------------------------- |
| `bschimke95`           | Heavy LLM user, general k8s | General reviews, AI-generated code |
| `berkayoz`             | Networking, MicroK8s        | Network changes, MicroK8s PRs      |
| `HomayoonAlimohammadi` | General k8s, CAPI           | General                            |
| `mateoflorido`         | Charmed Kubernetes          | CK-related changes                 |
| `ktsakalozos`          | Manager                     | Only for management approval       |
