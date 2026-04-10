# Prompts

Single source of truth for all AI agent prompts — roles and workflows.

## What's where

| Location                           | Invocation              | Purpose                                      |
| ---------------------------------- | ----------------------- | -------------------------------------------- |
| `.github/prompts/*.prompt.md`      | `/name` in Copilot Chat | All prompts — roles and workflow templates   |
| `.github/agents/*.agent.md`        | `@name` in Copilot Chat | Thin wrappers → reference `.github/prompts/` |
| `.github/chat-modes/*.chatmode.md` | Mode picker dropdown    | Thin wrappers → reference `.github/prompts/` |

## Role prompts

Type `/reviewer`, `/architect`, `/developer`, `/devops`, or `/security` in Copilot Chat.

| Role          | Focus                                          |
| ------------- | ---------------------------------------------- |
| **Architect** | System design, trade-offs, decision records    |
| **Developer** | Implementation, clean code, minimal diffs      |
| **Reviewer**  | Code review, severity-rated findings, verdicts |
| **DevOps**    | CI/CD, pipelines, infrastructure automation    |
| **Security**  | Vulnerability analysis, OWASP, threat modeling |

## Workflow prompts

Type `/batch-processing`, `/resume-session`, `/enumerate-repos`, or `/progress-tracking` and supply your campaign variables.

## Starting a new campaign

1. Create a project directory under `projects/` with `scripts/`, `context/`, and a `PROGRESS.yaml`.
2. Use `/enumerate-repos` to list and batch the target repos.
3. Use `/batch-processing` with your campaign's variables to process each batch.
4. In a new session, use `/resume-session` to pick up where you left off.
