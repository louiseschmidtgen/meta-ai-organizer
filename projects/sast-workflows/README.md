# SAST Workflows Project

Implement Static Application Security Testing (SAST) scanning workflows across
Canonical Kubernetes repositories, as recommended by the security team.

## Background

Security researchers have identified severe vulnerabilities — including remote
code execution — in our public codebases. In most cases, the vulnerability was
easily discovered (i.e., an open-source SAST tool immediately flagged the root
cause with no special configuration).

**Company policy:** Every repository must implement a SAST scanning workflow.

> Note: This is recommended even if the repository is onboarded to SSDLC;
> TIOBE has missed some recent vulnerabilities.

## Tools

| Tool                                             | Scope           | License                     | Notes                                                   |
| ------------------------------------------------ | --------------- | --------------------------- | ------------------------------------------------------- |
| [Bandit](https://bandit.readthedocs.io/)         | Python-specific | OSS                         | Catches common Python security anti-patterns            |
| [Semgrep](https://semgrep.dev/)                  | Multi-language  | OSS CLI (no account needed) | Community rulesets for Python, GitHub Actions, Go, etc. |
| [OpenGrep](https://github.com/opengrep/opengrep) | Multi-language  | OSS (Semgrep fork)          | Fully open-source alternative                           |
| [CodeQL](https://codeql.github.com/)             | Multi-language  | Partly OSS (by GitHub)      | Deep semantic analysis, SARIF output                    |

## Rollout Plan

### V1 — Pilot (2 repositories)

| Repository                                        | Bandit                                                        | Semgrep                                                       | Status  |
| ------------------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------- | ------- |
| [k8s-snap](https://github.com/canonical/k8s-snap) | ✅ [PR #2466](https://github.com/canonical/k8s-snap/pull/2466) | ✅ [PR #2468](https://github.com/canonical/k8s-snap/pull/2468) | Merged  |
| [k8sd](https://github.com/canonical/k8sd)         | N/A (Go-only repo)                                            | 🔲 To do                                                       | Pending |

> k8sd is a pure Go repository — Bandit (Python-only) does not apply.
> Semgrep with Go + GitHub Actions rulesets is the primary SAST tool here.

### V2 — Broader rollout

Roll out to remaining repositories listed in `../Repositories/repositories.yaml`.

## Reference Implementation

The k8s-snap PRs serve as the reference:

- **Bandit (Python):** Added to existing `python-lint` CI job via tox environments.
  Blocks on HIGH severity only (`-lll` flag).
- **Semgrep:** Standalone workflow (`.github/workflows/semgrep.yaml`).
  Advisory-only initially; results uploaded to GitHub Security tab via SARIF.

## Files

- `context/` — Background docs, policy references, and implementation notes
- `workflows/k8sd/` — Ready-to-PR workflow files for the k8sd repository
