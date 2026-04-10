# Agent Scheduler — Kubernetes for AI Agents

## The Idea

An orchestration layer that automatically dispatches AI agent workflows in response to events — like Kubernetes schedules pods, but for LLM agent tasks across our ~270 repos.

## Kubernetes Analogy

| Kubernetes Concept | Agent Equivalent                           | We Already Have |
| ------------------ | ------------------------------------------ | --------------- |
| Pod Spec           | Prompt file (`.github/prompts/*.prompt.md`) | ✅               |
| Container Image    | LLM + MCP tools                           | ✅               |
| ConfigMap/Secret   | `context/` dirs, Jira/GitHub credentials   | ✅               |
| Deployment         | Project (`projects/<name>/`)               | ✅               |
| Job/CronJob        | Scheduled agent runs                       | ❌               |
| Controller         | Event-driven prompt invocation             | ❌               |
| etcd               | State store (PROGRESS.yaml)                | ✅ (manual)      |
| kubelet            | Agent runtime (VS Code / CLI)              | ✅ (manual)      |
| kube-scheduler     | **This is the gap**                        | ❌               |

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  Event Sources                   │
│  GitHub webhooks │ Jira webhooks │ Cron schedule │
└────────┬─────────┴───────┬───────┴───────┬──────┘
         │                 │               │
         ▼                 ▼               ▼
┌─────────────────────────────────────────────────┐
│              Agent Scheduler                     │
│                                                  │
│  Event → Match Rule → Select Prompt → Dispatch   │
│                                                  │
│  Rules:                                          │
│  - PR review submitted → /address-review         │
│  - Issue created with label "security" → /review │
│  - Monday 9am → /triage-sprint                   │
│  - PR merged → update PROGRESS.yaml              │
│  - New Jira ticket assigned → /work-on-ticket    │
│  - Every 5 min → /scan-and-fix-cves             │
└────────┬─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│              Agent Runtime                       │
│                                                  │
│  - Load prompt + context                         │
│  - Connect MCP tools                             │
│  - Execute with gates (human approval queue)     │
│  - Write results to state store                  │
│  - Report back (Slack/email/PR comment)          │
└─────────────────────────────────────────────────┘
```

## Three Architecture Options

### Option A: GitHub Actions as Scheduler (Pragmatic)

**How it works:**
- GitHub webhook events already trigger Actions
- Add a workflow that calls an LLM API (Anthropic/OpenAI) with our prompt files
- State lives in this repo (PROGRESS.yaml commits)
- Human gates become PR approvals or Slack notifications

**Pros:**
- No infrastructure to manage
- Free CI minutes for public repos
- Already integrated with GitHub events

**Cons:**
- LLM doesn't have MCP tools in CI — would need to use REST APIs directly
- 6-hour job timeout
- Rate limits on LLM API calls
- Hard to debug agent behavior in CI logs

**Best for:** Simple automations (PR merged → update tracker, schedule → run report)

### Option B: Local Daemon with Event Polling (DIY)

**How it works:**
- Python script that polls GitHub notifications + Jira board every N minutes
- Matches events to prompt rules defined in a YAML config
- Invokes `claude` CLI or Copilot CLI with the right prompt
- Runs on your machine or a server
- Full MCP tool access since it runs locally

**Pros:**
- Full access to MCP tools (GitHub, Atlassian)
- Can use `claude` CLI or Copilot CLI directly
- Easy to prototype and iterate
- Can run on any machine with credentials

**Cons:**
- Needs a machine running 24/7 (or laptop open)
- Polling instead of real-time webhooks
- Single point of failure
- No built-in queue or retry logic

**Best for:** Prototyping, personal automation, the CVE scanner use case

### Option C: GitHub App + Webhook Server (Production-Grade)

**How it works:**
- Proper webhook receiver (deployed on a server, Lambda, or Cloud Run)
- Event matching engine with priority queue
- Calls LLM API with tool-use for GitHub/Jira operations
- Dashboard for observability
- Persistent state in a database

**Pros:**
- Real-time event processing
- Scalable to many repos
- Proper retry, deduplication, rate limiting
- Audit trail and observability

**Cons:**
- Most complex to build and operate
- Needs infrastructure (server, DB, secrets management)
- GitHub App registration and permissions
- Cost of LLM API calls at scale

**Best for:** Team-wide deployment, production security scanning

## Recommendation

**Start with Option B** to prototype the CVE scanner. It can be running in a day and immediately provides value. If it proves useful, extract the core into Option C for production.

## Existing Tools in This Space

| Project                   | What it does                                         | Analogy           |
| ------------------------- | ---------------------------------------------------- | ----------------- |
| **CrewAI**                | Multi-agent teams with roles, tasks, process flows   | Team of specialists |
| **LangGraph** (LangChain) | Stateful agent graphs with cycles, checkpoints       | DAG/workflow engine |
| **AutoGen** (Microsoft)   | Multi-agent conversations with human-in-the-loop     | Chat-based orchestration |
| **OpenAI Swarm**          | Lightweight agent handoffs                           | Load balancer     |
| **Semantic Kernel** (MS)  | Plugin-based agent orchestration                     | Middleware        |
| **Julep**                 | Stateful long-running agent workflows with persistence | Job scheduler   |
| **AgentOS / Agent Protocol** | Standardized API for agent lifecycle              | Container runtime interface |
| **Letta (MemGPT)**        | Agents with persistent memory and state management   | Stateful pods     |

## Date

2026-04-10 — Initial brainstorm
