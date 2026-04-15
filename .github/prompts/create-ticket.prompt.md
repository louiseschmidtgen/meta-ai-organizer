---
description: "Create a Jira ticket from a task description — with sprint, epic, and story points"
---

# Create Ticket — Jira Story from Task Description

You are creating a Jira ticket in the KU (Kubernetes-ENG) project on `warthogs.atlassian.net`.

## Workflow

### Step 1 — Understand the task

The user will describe what needs to be done. Extract:

- **Summary** — concise one-line title
- **Description** — what the task involves, why it's needed
- **Acceptance Criteria** — checklist of verifiable conditions for done
- **Type** — Story (default) or Spike (exploratory/research work)
- **Story points** — estimate based on complexity (max 3 per card):
  - 1 = trivial (typo fix, config change, small review)
  - 2 = small (single-file change, straightforward PR)
  - 3 = medium (multi-file change, some investigation needed)
  - If the estimate exceeds 3, **split the work into multiple tickets** and explain the breakdown to the user

### Step 2 — Determine sprint and epic

1. Find the current active sprint:
   - Search for a recent KU ticket to discover the active sprint ID
   - Or ask the user which sprint/pulse to add it to
2. Ask the user which epic (parent) to link to, or suggest one based on context:
   - KU-5581 = "Security Actions - March 2026" (security hardening, SAST, pinning)
   - KU-5765 = "CVE Remediation — High & Critical Vulnerability Backlog"
   - KU-5766 = "Pod Patrol — AI-Assisted Security Maintenance for Canonical Kubernetes"
   - If unsure, ask

### Step 3 — Present before creating

Show the user the ticket details before creating:

```
Summary: <title>
Type: Story | Spike
Story Points: <estimate>
Sprint: <sprint name>
Epic: <epic key> — <epic summary>
Priority: Medium (default)
Assignee: Louise Schmidtgen

Description:
<formatted description>

Acceptance Criteria:
- [ ] <criterion 1>
- [ ] <criterion 2>
```

Ask: "Look good? Anything to adjust before I create it?"

### Step 4 — Create the ticket

Use Atlassian MCP to create the issue:

- `cloudId`: `warthogs.atlassian.net`
- `projectKey`: `KU`
- `issueTypeName`: `Story` (or `Spike`)
- `contentFormat`: `markdown`
- Include in `additional_fields`:
  - `customfield_10016`: story points estimate
  - `customfield_10020`: sprint ID
  - `customfield_10614`: acceptance criteria — **must be ADF format** (taskList with taskItem nodes, state "TODO")
  - `parent`: epic key
  - `priority`: `{"name": "Medium"}`
  - `assignee`: `{"accountId": "712020:f1305b2b-2c08-4b28-87b8-85031d178a6f"}`

#### Acceptance Criteria ADF format

`customfield_10614` requires Atlassian Document Format. Use this structure:

```json
{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "taskList",
      "attrs": { "localId": "ac-1" },
      "content": [
        {
          "type": "taskItem",
          "attrs": { "localId": "ac-1-1", "state": "TODO" },
          "content": [{ "type": "text", "text": "Criterion text here" }]
        }
      ]
    }
  ]
}
```

Increment `localId` for each item (ac-1-1, ac-1-2, etc.).

### Step 5 — Confirm

Report the created ticket key and link:

```
Created KU-XXXX: <summary>
https://warthogs.atlassian.net/browse/KU-XXXX
```

## Description template

Structure the description in markdown:

```markdown
## Goal

<What needs to be done and why>

## Scope

- <specific task 1>
- <specific task 2>

## Repos affected

- <repo list, if applicable>

## Notes

<Any additional context, links, related tickets>
```

## Tips

- If the user mentions multiple repos, consider whether this should be one ticket or multiple
- Link related PRs in the description if they exist
- If the task is vague, ask 1-2 clarifying questions — don't create an underspecified ticket
- Default priority is Medium unless the user says it's urgent (High) or low-priority (Low)
