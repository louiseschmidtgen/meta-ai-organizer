# k8sd Repository Context

## Overview

- **Repo:** <https://github.com/canonical/k8sd>
- **Language:** Go (98.9%), Makefile (1.1%)
- **Description:** Cluster-management daemon for Canonical Kubernetes
- **Binaries:** k8sd, k8s (CLI), k8s-apiserver-proxy

## Repository Structure

```
.github/
  workflows/
    backport.yaml
    cla.yaml
    go.yaml              # existing Go lint + unit tests
    lint_pr.yaml
    microcluster-check.yaml
    stale-cron.yaml
    tics.yaml
    trivy.yaml           # existing Trivy vulnerability scanning
    update-go-deps.yaml
cmd/
hack/
pkg/
.gitignore
.golangci.yml            # golangci-lint v2 config
LICENSE
Makefile
README.md
SECURITY.md
go.mod
go.sum
```

## Existing CI

- **go.yaml** — runs on PRs: go fmt, go vet, go test, golangci-lint v2.7.2
- **trivy.yaml** — Trivy container/dependency vulnerability scanning
- **lint_pr.yaml** — PR title/body linting
- **cla.yaml** — CLA check

## Key Observations for SAST

1. **Pure Go repo** — no Python code, so Bandit does not apply.
2. **Has GitHub Actions workflows** — Semgrep `p/github-actions` ruleset is
   relevant for detecting shell injection in workflow files.
3. **Semgrep `p/go` ruleset** — covers Go security patterns (SQL injection,
   path traversal, command injection, crypto misuse, etc.).
4. **Already has Trivy** — Trivy covers dependency/container vulnerabilities
   but does NOT do source-code SAST like Semgrep does.

## SAST Plan for k8sd

Add a Semgrep workflow (`.github/workflows/semgrep.yaml`) that:
- Runs on push to `main` and `release-*` branches
- Runs on PRs (excluding docs-only changes)
- Scans with `p/go` and `p/github-actions` rulesets
- Uploads SARIF results to GitHub Security tab
- Advisory-only initially (no `--error` flag)
