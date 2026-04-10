---
description: "Review a teammate's PR from a Jira ticket — fetch, analyze, post review"
---

# Review Ticket — Jira-to-PR Code Review Workflow

You are performing a code review on behalf of the user. Follow the reviewer role in `.github/prompts/reviewer.prompt.md` for review standards and output format.

## Workflow

### Step 1 — Fetch the Jira ticket

Use Atlassian MCP to fetch the ticket details:

- Ticket key: `{{TICKET}}` (e.g. `KU-1234`)
- Read: summary, description, acceptance criteria, comments, linked issues
- Note the assignee (who wrote the code) and any relevant context

### Step 2 — Find the associated PR

Look for the PR in this order:

1. **Jira links** — check the ticket's remote links / development panel for GitHub PR URLs
2. **Branch search** — search GitHub for branches matching the ticket key (e.g. `KU-1234/`)
3. **PR search** — search open PRs across `canonical` and `charmed-kubernetes` orgs by the assignee or related keywords
4. If multiple PRs are found, list them and ask the user which to review
5. If no PR is found, tell the user and stop

### Step 3 — Understand the context

Before reading code, understand **what** the PR is supposed to do:

1. Re-read the Jira ticket description and acceptance criteria
2. Read the PR description
3. Check if there are linked design docs or related tickets
4. Form a mental model: "This PR should do X to solve Y"

### Step 4 — Fetch and analyze the diff

1. Use GitHub MCP to read the PR diff (files changed, additions, deletions)
2. For large PRs (>500 lines changed), skim the file list first and prioritize:
   - New files (highest risk — no existing tests)
   - Modified core logic (business logic, auth, data handling)
   - CI/workflow changes (supply-chain risk)
   - Test files (review last — check coverage, not style)
3. For each changed file, read enough surrounding context to understand the change
4. If the PR touches a repo you can clone, consider cloning to read full file context

### Step 5 — Perform the review

Apply the full reviewer checklist from `.github/prompts/reviewer.prompt.md`. Additionally check:

- **Does it match the ticket?** — Does the code actually implement what the Jira ticket asked for?
- **Acceptance criteria** — Are all acceptance criteria from the ticket satisfied?
- **Missing work** — Is anything from the ticket description NOT addressed by the PR?
- **Scope creep** — Does the PR do things NOT requested in the ticket?

Structure the review as:

```markdown
## Review: {{PR_TITLE}}

**PR:** {{PR_URL}}
**Author:** {{AUTHOR}}
**Repo:** {{ORG}}/{{REPO}}

### Ticket alignment

- [ ] PR implements what the ticket describes
- [ ] All acceptance criteria addressed
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
```

### Step 6 — Present to user before posting

**Always show the full review to the user first.** Ask:

> "Ready to post this review on the PR? I'll submit as REQUEST CHANGES / APPROVE / COMMENT. Shall I proceed, or would you like to adjust anything?"

### Step 7 — Post the review (only after user approval)

Use GitHub MCP to submit the review on the PR:

1. Create a pending review
2. Add line-specific comments for each finding (if applicable)
3. Submit with the appropriate verdict (APPROVE / REQUEST_CHANGES / COMMENT)

## Variables

| Variable     | Description     | Example   |
| ------------ | --------------- | --------- |
| `{{TICKET}}` | Jira ticket key | `KU-1234` |

Everything else is discovered automatically from the ticket and PR.

## Tips

- If the PR is trivial (docs-only, typo fix), say so quickly. Don't over-review.
- If you're unsure about domain-specific logic, flag it as 🟡 and suggest the user verify.
- For Go code, check error handling rigorously — it's the #1 source of bugs.
- For CI/workflow changes, apply the DevOps and Security checklists too.
