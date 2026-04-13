# Canonical AI Platform — Self-Hosted LLM Inference & Agent Infrastructure on K8s

## One-Liner

A K8s-native platform for self-hosting LLM inference and managing AI agent toolchains (MCP servers), distributed as secured ROCKs and snaps — the way Canonical ships software.

## Why Now

1. **AI funding will correct** — when subsidies dry up, enterprises and governments will need to run LLMs locally or on private GPU farms instead of paying per-token to cloud APIs. llm-d and vLLM Production Stack prove the K8s-native self-hosting pattern works today.
2. **MCP protocol explosion** — Model Context Protocol (MCP) is becoming the standard for connecting AI agents to tools and data. Nobody is distributing a managed, authenticated MCP server layer yet.
3. **Canonical distributes software** — snaps, ROCKs, charms. Packaging upstream inference engines and agent gateways as hardened, supported artifacts is exactly what Canonical does.
4. **Secured containers for AI** — enterprises won't run inference workloads or autonomous agents without CVE-scanned images, access control, and isolation. Hot topic, getting hotter.

## Core Thesis (Kos)

> Canonical distributes software. On top of that, we secure containers. These two things together applied to AI workloads = product.

This follows the Kubeflow pattern: a developer builds the first charms, demonstrates value, leadership says "+1 let's make it a product."

## Components

### 1. Inference on K8s

Self-hosted LLM serving as a first-class k8s-snap feature.

| What | Upstream | Notes |
|------|----------|-------|
| Inference engine | [vLLM Production Stack](https://github.com/vllm-project/production-stack) (2.3k stars, Helm-based) | Reference K8s deployment for vLLM with router, autoscaling, observability |
| Distributed inference | [llm-d](https://llm-d.ai/) (Red Hat-backed, v0.5) | K8s-native framework: inference scheduler, KV cache, prefill/decode disaggregation |
| Local inference | [canonical/inference-snaps](https://github.com/canonical/inference-snaps) | **Already exists** — snaps that auto-detect CPU/GPU/NPU and optimize runtime+weights |
| Model routing | [K8s Inference Gateway](https://gateway-api.sigs.k8s.io/geps/gep-3171/) | SIG extension for GPU-aware, model-aware routing |

**UX vision:**
```bash
sudo k8s enable inference
sudo k8s set inference.model=deepseek-r1
sudo k8s set inference.hardware=auto    # auto-detect GPU/NPU
# → model deploys as pods, OpenAI-compatible API available on cluster
```

Inference snaps already handle the single-node case. The gap is multi-node K8s deployment with proper scheduling, scaling, and routing.

### 2. MCP Server Management

Manage, authenticate, and federate MCP (Model Context Protocol) servers so AI agents can securely access tools and data sources.

| What | Upstream | Notes |
|------|----------|-------|
| MCP/A2A gateway | [agentgateway](https://github.com/agentgateway/agentgateway) (2.4k stars, Linux Foundation) | Proxy for agent-to-LLM, agent-to-tool, agent-to-agent traffic |
| Auth & access control | agentgateway built-in | JWT, API keys, OAuth, CEL policy engine, rate limiting |
| Tool federation | agentgateway MCP support | Connect LLMs to tools via MCP with transport support (stdio/HTTP/SSE) |
| Guardrails | agentgateway guardrails | Regex, moderation APIs, custom webhooks for content filtering |

Solo.io originally built this (as Gloo Gateway → agentgateway), then donated it to the Linux Foundation. It's Apache-2.0 and the most mature MCP gateway project.

**What it solves:** control which users/agents can access which MCP tools, authenticate callers, audit tool invocations, rate-limit usage.

### 3. Secured AI ROCKs

OCI container images for all AI infrastructure components, built the Canonical way.

- vLLM engine ROCK
- llm-d router ROCK
- agentgateway ROCK
- Model server ROCKs (per-model or generic)

Same value proposition as existing K8s ROCKs (coredns-rock, metrics-server-rock, etc.): Ubuntu-based, CVE-scanned, minimal attack surface, long-term support.

### 4. K8s-Native Agent Isolation

AI agents running as pods need isolation guarantees beyond what standard K8s provides:

- **Per-agent pods** — each agent runs in its own pod with restricted capabilities
- **Network policies** — agents communicate through the gateway, not directly
- **Resource quotas** — prevent runaway inference or token consumption
- **Audit trail** — every tool call, model query, and agent action is logged

This matters because autonomous agents with tool access (file systems, databases, APIs via MCP) are a new attack surface. An agent that can call arbitrary MCP tools is essentially an autonomous process with credentials.

## Competitive Landscape

| Player | What | Missing |
|--------|------|---------|
| **vLLM Production Stack** | K8s inference via Helm | No security hardening, no MCP/agent layer, no distribution |
| **llm-d** (Red Hat) | K8s inference framework | Red Hat ecosystem, no MCP story |
| **agentgateway** (LF) | MCP/A2A proxy | No inference, no container hardening, raw upstream only |
| **NVIDIA NIM** | GPU-optimized inference | Proprietary, expensive, vendor lock-in |
| **Ollama** | Local LLM runner | Single-node, no K8s, no enterprise features |

Nobody combines: inference + MCP management + secured containers + enterprise distribution.

## Risks

| Risk | Reality |
|------|---------|
| New product = hard to get buy-in | Follow Kubeflow playbook: build first, demo, get +1. Not asking for permission first |
| llm-d is Red Hat-backed | Build on vLLM (vendor-neutral), support both engines |
| agentgateway is Solo.io-dominated | It's a LF project (Apache-2.0), open governance |
| AI bubble pops | Self-hosting demand *increases* when bubble pops — that's the thesis |
| Small team bandwidth | Start with inference ROCK (exists as snap), iterate incrementally |

## Phased Approach

### Phase 1 — Inference on K8s
- Ship vLLM as a ROCK, test on k8s-snap
- Explore `sudo k8s enable inference` UX via FeatureController
- Leverage existing inference-snaps work for model/hardware detection

### Phase 2 — MCP Gateway
- Package agentgateway as a ROCK
- Deploy on k8s-snap, wire up auth and tool federation
- `sudo k8s enable agent-gateway`

### Phase 3 — Product Pitch
- Demo: inference + MCP gateway running on Canonical K8s in 5 minutes
- Discourse post: "Self-Hosting LLMs on Canonical K8s"
- Pitch to leadership with working prototype

## Links

- [vLLM Production Stack](https://github.com/vllm-project/production-stack) — K8s inference reference stack
- [llm-d](https://llm-d.ai/) — K8s-native distributed inference (Red Hat)
- [agentgateway](https://github.com/agentgateway/agentgateway) — MCP/A2A/LLM gateway (Linux Foundation)
- [canonical/inference-snaps](https://github.com/canonical/inference-snaps) — existing Canonical inference packaging
- [Inference Snaps docs](https://documentation.ubuntu.com/inference-snaps/) — Ubuntu documentation
- [K8s Inference Gateway GEP](https://gateway-api.sigs.k8s.io/geps/gep-3171/) — SIG extension for model routing

## Date

2026-04-13 — Initial product concept
