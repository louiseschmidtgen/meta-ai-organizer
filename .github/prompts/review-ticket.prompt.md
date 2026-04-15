---
description: "Code review from any source — Jira ticket, GitHub PR URL, or GitHub comment URL"
---

# Review — Code Review Workflow

You are performing a code review on behalf of the user. Follow the reviewer role in `.github/prompts/reviewer.prompt.md` for review standards and output format.

## Input

The user provides **one or more** of:

| Input type            | Example                                                               |
| --------------------- | --------------------------------------------------------------------- |
| Jira ticket key       | `KU-1234`                                                             |
| GitHub PR URL         | `https://github.com/canonical/k8s-snap/pull/2517`                     |
| GitHub review/comment | `https://github.com/canonical/repo/pull/113#pullrequestreview-408...` |

If both a Jira ticket and a PR URL are given, use the Jira ticket for acceptance criteria context and the PR URL for the code review. Otherwise, detect which type was given and follow the matching path below.

## Workflow

### Step 1 — Resolve the input to a PR

**If Jira ticket:**

1. Fetch ticket via Atlassian MCP (`cloudId: warthogs.atlassian.net`)
2. Read: summary, description, acceptance criteria, comments, linked issues
3. Find the PR:
   - Check the ticket's remote links for GitHub PR URLs
   - Search GitHub for branches matching the ticket key (e.g. `KU-1234/`)
   - Search open PRs across `canonical` and `charmed-kubernetes` orgs by the assignee
4. If multiple PRs found, list them and ask the user which to review
5. If no PR found, tell the user and stop

**If GitHub PR URL:**

1. Parse owner, repo, and PR number from the URL
2. Fetch PR details via GitHub MCP

**If GitHub review/comment URL:**

1. Parse owner, repo, PR number, and review/comment ID from the URL
2. Fetch PR details and the specific review/comment via GitHub MCP
3. Note the reviewer's feedback — this is what we're responding to
4. Determine the mode:
   - **User is the PR author** → respond to reviewer feedback (Step 7)
   - **User is NOT the PR author** → review the PR (Steps 2–6)

### Step 2 — Understand the context

Before reading code, understand **what** the PR is supposed to do:

1. Read the PR description and any linked context (Jira ticket if available, design docs)
2. Read existing reviews and comments — don't repeat what others have already said
3. If a specific review/comment was provided, read it carefully
4. Form a mental model: "This PR should do X to solve Y"

### Step 3 — Fetch and analyze the diff

1. Use GitHub MCP to read the PR diff (files changed, additions, deletions). If the MCP returns 404 (common for internal `canonical/*` repos), fall back to `gh pr diff` and `gh pr view` via the CLI.
2. For large PRs (>500 lines changed), skim the file list first and prioritize:
   - New files (highest risk — no existing tests)
   - Modified core logic (business logic, auth, data handling)
   - CI/workflow changes (supply-chain risk)
   - Test files (review last — check coverage, not style)
3. For each changed file, read enough surrounding context to understand the change
4. If the PR touches a repo you can clone, consider cloning to read full file context
5. Verify pinned action SHAs against their tagged releases (for CI/workflow changes)
6. For CI/workflow PRs, check if the same changes need to apply to other long-lived branches (e.g. release branches, pre-release branches)

### Step 4 — Perform the review

Apply the full reviewer checklist from `.github/prompts/reviewer.prompt.md`. Additionally check:

- **Does it match the intent?** — Does the code implement what the PR/ticket describes?
- **Acceptance criteria** — Are all stated criteria satisfied?
- **Missing work** — Is anything described but NOT addressed?
- **Scope creep** — Does the PR do things NOT requested?
- **PR description accuracy** — Does the description match what the code actually does?

For each finding, include a **concrete code suggestion** when possible. When posting via `gh pr review` (single review body), use fenced code blocks. When posting via GitHub MCP with line-comment support, use GitHub's suggestion syntax:

````markdown
```suggestion
corrected code here
```
````

Structure the review as:

```markdown
## Review: {{PR_TITLE}}

**PR:** {{PR_URL}}
**Author:** {{AUTHOR}}
**Repo:** {{ORG}}/{{REPO}}

### Alignment

- [ ] PR implements what it describes
- [ ] All stated criteria addressed
- [ ] No unrelated changes (scope creep)

### Findings

#### 🔴 Blockers

(list or "None")

#### 🟡 Warnings

(list or "None")

#### 🔵 Nits

(list or "None")

### Summary

- 🔴 Blockers: X
- 🟡 Warnings: Y
- 🔵 Nits: Z
- Verdict: APPROVE / REQUEST CHANGES / NEEDS DISCUSSION

> **Note:** This PR review was created with the help of an AI assistant.
```

### Step 5 — Present to user before posting

**Always show the full review to the user first.** Ask:

> "Ready to post this review? I'll submit as APPROVE / REQUEST CHANGES / COMMENT via `gh pr review`. Shall I proceed, or would you like to adjust anything?"

### Step 6 — Post the review (only after user approval)

Use GitHub MCP to submit the review on the PR:

1. If the user is the PR author → submit as COMMENT (GitHub blocks self-approval)
2. If the user is NOT the author → submit with the appropriate verdict (APPROVE / REQUEST_CHANGES / COMMENT)
3. For line-specific findings, post as review comments via GitHub MCP when available; otherwise include all findings in the review body via `gh pr review`

### Step 7 — Respond to review feedback (when user is the PR author)

If the user provided a review/comment URL and they are the PR author:

1. Analyze each point the reviewer raised
2. Triage each point:
   - **Actionable fix** — make the code/description change, then reply explaining what was done
   - **Question** — draft a clear answer with evidence (e.g. tool output, docs links)
   - **Disagreement** — draft a respectful reply explaining the rationale
   - **Out of scope** — acknowledge and suggest follow-up work
3. If changes are needed:
   - Clone the repo and check out the PR branch
   - Make fixes, run lint/tests
   - Stage changes and give the user the commit command (they sign all commits)
   - Update the PR description if it was inaccurate
4. Draft reply comment(s) and show to the user

🚦 **Gate: Ask user before posting replies or pushing changes.**

## Variables

| Variable    | Description                                    | Example                                           |
| ----------- | ---------------------------------------------- | ------------------------------------------------- |
| `{{INPUT}}` | Jira ticket key, GitHub PR URL, or comment URL | `KU-1234` or `https://github.com/org/repo/pull/1` |

Everything else is discovered automatically.

## Tips

- If the PR is trivial (docs-only, typo fix), say so quickly. Don't over-review.
- If you're unsure about domain-specific logic, flag it as 🟡 and suggest the user verify.
- For Go code, check error handling rigorously — it's the #1 source of bugs.
- For CI/workflow changes, apply the DevOps and Security checklists too.
- Don't repeat findings already raised by other reviewers — reference and agree instead.
- When verifying tool output (Bandit, golangci-lint, etc.), clone and re-run locally for evidence.
- If the input is a review comment and the user is the author, focus on responding — not re-reviewing.
