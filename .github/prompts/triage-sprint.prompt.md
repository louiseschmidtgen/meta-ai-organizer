---
description: "Review your Jira sprint board — summarize status, suggest what to pick up next"
---

# Triage Sprint — Review Board and Plan Next Work

Look at the current sprint, summarize what's in progress, and suggest what to work on next.

## Workflow

### Step 1 — Find the active sprint

1. Search for a recent KU ticket to discover the active sprint name and ID
2. Query all tickets in the current sprint via JQL:
   ```
   project = KU AND sprint in openSprints() AND assignee = currentUser() ORDER BY priority DESC, created ASC
   ```
3. Also fetch unassigned tickets in the sprint that might need pickup:
   ```
   project = KU AND sprint in openSprints() AND assignee is EMPTY ORDER BY priority DESC
   ```

### Step 2 — Categorize tickets

Group by status:

```
## Sprint: <sprint name> (<start> → <end>)

### 🔴 Blocked (X)
- KU-XXXX: <summary> — <why blocked>

### 🟡 In Progress (X)
- KU-XXXX: <summary> — <current state, PR link if exists>

### 🔵 In Review (X)
- KU-XXXX: <summary> — <PR link, reviewer, CI status>

### ✅ Done (X)
- KU-XXXX: <summary>

### ⬜ To Do (X)
- KU-XXXX: <summary> — <priority, story points>

### 🆓 Unassigned (X)
- KU-XXXX: <summary> — <priority, story points>
```

### Step 3 — Check PR status for in-review tickets

For each "In Review" ticket:

1. Find the linked PR
2. Check: CI status, reviewer comments, approval status
3. Flag any PRs that need attention (failing CI, unaddressed comments, stale)

### Step 4 — Suggest next action

Based on the board state, recommend what to do:

1. **Unaddressed review comments** → `/address-review` on that PR
2. **PRs with failing CI** → fix CI issues
3. **Stale PRs (no activity >3 days)** → ping reviewer or rebase
4. **Highest priority To Do** → `/work-on-ticket` on that ticket
5. **Unassigned tickets you could grab** → suggest picking one up

Present as:

```
## Suggested next action

1. 🔥 Address review on KU-XXXX (PR #N has unresolved comments)
2. ⚡ Fix CI on KU-XXXX (PR #N failing since <date>)
3. 📋 Pick up KU-XXXX (highest priority unstarted, N SP)

Which one? Or tell me what you'd like to work on.
```

### Step 5 — Sprint health summary

```
## Sprint health

Capacity: X SP total | Y SP done | Z SP in progress | W SP to do
Days remaining: N
Velocity needed: W SP in N days

⚠️ At risk: <any tickets unlikely to finish in time>
```

## Tips

- Run this at the start of a work session to orient yourself
- If the sprint is overloaded, suggest moving low-priority items to backlog
- Check if any "Done" tickets need Jira transitions (still showing "In Review" etc.)
- For "In Review" PRs, check if the reviewer is from the team list in `copilot-instructions.md`
