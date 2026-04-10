---
description: "Address reviewer feedback on a PR — read comments, fix issues, push updates"
---

# Address Review — Work Through PR Feedback

A reviewer has left comments on your PR. Read each comment, fix the issues, and push updates.

## Workflow

### Step 1 — Fetch the review

1. Identify the PR: the user provides a PR URL, number, or the ticket key
2. Use GitHub MCP to fetch:
   - Review comments (line-specific feedback)
   - General PR comments
   - Review verdict (approved, changes requested, commented)
3. List all unresolved threads

### Step 2 — Triage the feedback

Categorize each comment:

| Category           | Action                                                       |
| ------------------ | ------------------------------------------------------------ |
| **Actionable fix** | Code change needed — do it                                   |
| **Question**       | Reviewer needs clarification — draft a reply                 |
| **Disagreement**   | You think the code is correct — draft a reply explaining why |
| **Nit / style**    | Fix it, it's cheap                                           |
| **Out of scope**   | Acknowledge, suggest follow-up ticket                        |

Present the triage to the user:

```
## Review feedback on PR #<number>

Reviewer: @<handle>
Verdict: CHANGES_REQUESTED | COMMENTED

### Will fix (X items)
1. <file>:<line> — <summary of fix>
2. ...

### Will reply (Y items)
1. <comment summary> — <draft reply>
2. ...

### Out of scope (Z items)
1. <comment summary> — suggest follow-up
```

🚦 **Gate: Ask user to confirm the triage.** "Does this look right? Anything you'd handle differently?"

### Step 3 — Apply fixes

1. Check out the PR branch
2. Make each fix as a focused change
3. Run lint and tests after all fixes are applied
4. Stage changes and give the user the commit command:
   > Run: `git commit -S -m "fix: address review feedback"`

### Step 4 — Reply to comments

For each "question" or "disagreement" item:

1. Draft a reply
2. Show it to the user for approval
3. Post via GitHub MCP (add reply to the review thread)

For each "out of scope" item:

1. Suggest creating a follow-up ticket
2. Reply on the thread acknowledging the feedback

### Step 5 — Push and notify

1. Push the updated branch: `GIT_TERMINAL_PROMPT=0 git push origin <branch>`
2. Check CI status
3. If all comments addressed, add a PR comment:
   > "Addressed all review feedback. Ready for re-review. See latest commit(s)."

🚦 **Gate: Ask user before posting the "ready for re-review" comment.**

### Step 6 — Report

```
## Review feedback addressed: PR #<number>

Fixed: X items
Replied: Y items
Out of scope: Z items (follow-up suggested)
CI: ✅ passing | ❌ needs attention

Pushed commit: <sha short>
```

## Tips

- Keep fix commits separate from new feature work — don't sneak in unrelated changes
- If a reviewer's suggestion improves the code, just do it. Don't argue nits.
- If you genuinely disagree, explain your reasoning once. If the reviewer insists, defer to them.
- For Go: re-run `go mod tidy` if dependencies changed
- User signs all commits — never commit directly
