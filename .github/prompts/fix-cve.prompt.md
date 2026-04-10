---
description: "Fix a CVE or security finding: dependency bump, code fix, or workflow hardening"
---

# Fix CVE — Security Remediation Workflow

Fix a security vulnerability identified by the CVE scanner. Takes a finding (from `STATE.yaml` or direct input) and produces a tested PR.

**Input:** One of:
- A finding from `projects/cve-scanner/STATE.yaml` (copy the YAML block)
- A Dependabot alert URL (e.g. `https://github.com/canonical/k8s-snap/security/dependabot/60`)
- A code scanning alert URL
- A CVE ID + repo name

## Step 1 — Parse the finding

Extract from the input:
- **Repo**: org/name
- **Source**: dependabot | code_scanning (Trivy, CodeQL, Scorecard)
- **Severity**: critical | high | medium
- **CVE/GHSA**: identifier
- **Package** (if dependency): name, current version, patched version
- **Rule** (if code scanning): rule ID, tool, location
- **Summary**: what the vulnerability is

If given a URL, fetch the alert details via `gh api` or GitHub MCP.

## Step 2 — Classify the fix type

| Source | Fix type | Approach |
|--------|----------|----------|
| Dependabot (Go) | Dependency bump | `go get <pkg>@<version> && go mod tidy` |
| Dependabot (Python) | Dependency bump | Update `requirements.txt`, `pyproject.toml`, or `setup.cfg` |
| Dependabot (npm) | Dependency bump | `npm install <pkg>@<version>` or update `package.json` |
| Dependabot (GitHub Actions) | Action pin update | Update SHA in workflow YAML |
| Trivy (rock image) | Base image / package update | Update `rockcraft.yaml` stage-packages or base version |
| CodeQL | Code fix | Apply the fix described in the alert, verify with CodeQL |
| Scorecard | Workflow hardening | Pin actions, add permissions, fix token scopes |

**Stop and ask the user** if:
- The fix requires a major version bump (breaking changes)
- The vulnerability is in vendored/copied code (not a managed dependency)
- Multiple CVEs affect the same package (batch them)
- The repo has no CI or tests to verify the fix

## Step 3 — Clone and branch

```bash
# Clone to /tmp for isolation
GIT_TERMINAL_PROMPT=0 git clone https://github.com/<org>/<repo>.git /tmp/cve-fix/<repo>
cd /tmp/cve-fix/<repo>
git checkout -b fix/<cve-id-or-package>
```

Branch naming: `fix/<cve-id>` for single CVEs, `fix/bump-<package>` for dependency bumps.

## Step 4 — Apply the fix

### Dependency bumps (Dependabot findings)

**Go:**
```bash
go get <package>@<patched-version>
go mod tidy
go build ./...
```

**Python:**
- Find which file declares the dependency: `grep -r "<package>" requirements*.txt pyproject.toml setup.cfg tox.ini`
- Update the version constraint to `>=<patched-version>`
- If pinned with `==`, update to `==<patched-version>`

**npm/Node:**
```bash
npm install <package>@<patched-version>
npm audit
```

### Rock image fixes (Trivy findings)

- Check `rockcraft.yaml` for `stage-packages` that pull in the vulnerable package
- Update the base image or override the package version
- If the vuln is in the base image and not in stage-packages, document it — may need to wait for upstream

### Code fixes (CodeQL/Semgrep)

- Read the alert details to understand the vulnerability
- Navigate to the file and line indicated
- Apply the fix following the tool's recommendation
- Run the relevant SAST tool locally to confirm the fix:
  - CodeQL: check if the alert would still trigger
  - Semgrep: `semgrep --config auto <file>`
  - Bandit: `bandit -r <directory>`

### Workflow hardening (Scorecard)

- Pin unpinned actions to commit SHAs
- Add restrictive `permissions:` blocks
- Fix token scope issues
- Reference existing patterns from the `pin-actions-to-sha` project

## Step 5 — Test

Run the repo's test suite to ensure the fix doesn't break anything:

| Language | Test command |
|----------|-------------|
| Go | `go test ./...` |
| Python | `pytest` or `tox` (check `tox.ini`, `pyproject.toml`) |
| Shell | `shellcheck` on modified scripts |
| Rocks | `rockcraft pack` (if feasible locally) |

Also run linters: `gofmt`, `black --check`, `ruff check`, `golangci-lint run`.

Check `Makefile`, `tox.ini`, `Justfile` for the repo's actual commands.

**Bail-out rule:** If tests fail after 3 fix attempts, stop and report. Don't loop.

## Step 6 — Commit

Stage changes, then tell the user to sign:

> Run: `cd /tmp/cve-fix/<repo> && git commit -S -m "fix: <description>"`

Commit message format:
- Dependency bump: `fix: bump <package> to <version> (CVE-YYYY-NNNNN)`
- Code fix: `fix: resolve <tool> finding in <file>`
- Workflow: `ci: harden workflow permissions` or `ci: pin actions to commit SHAs`

**Never include Jira ticket keys in commit messages.**

## Step 7 — Push and create PR

1. Push:
```bash
GIT_TERMINAL_PROMPT=0 git push origin fix/<branch-name>
```

2. Create PR via GitHub MCP:

**Title:** Same as commit message (conventional commit style)

**Body template:**
```markdown
## Security Fix

**CVE:** <CVE-ID> | **Severity:** <CRITICAL/HIGH/MEDIUM>
**Package:** <name> <old-version> → <new-version>
**Advisory:** <GHSA link>

## What changed

<Brief description of the fix>

## Verification

- [ ] Dependency updated to patched version
- [ ] Tests pass (`go test ./...` / `pytest` / etc.)
- [ ] No new lint warnings
- [ ] SAST tool confirms finding resolved (if applicable)
```

3. Request reviewer based on the repo:
   - `bschimke95` — general reviews, AI-generated code
   - `berkayoz` — networking, MicroK8s
   - `HomayoonAlimohammadi` — general k8s, CAPI
   - `mateoflorido` — Charmed Kubernetes

🚦 **Gate: Show the user the PR title and body before creating.**

## Step 8 — Update STATE.yaml

After PR is created, update the finding in `projects/cve-scanner/STATE.yaml`:
- Change `status: new` → `status: pr-open`
- This is manual for now — Phase 3 (dispatcher) will automate it

## Step 9 — Report

```
## Fixed: <CVE-ID> in <repo>

Severity: <CRITICAL/HIGH/MEDIUM>
Fix: <bumped X to Y / patched code in file.py / hardened workflow>
PR: <url>
CI: ✅ passing | ⚠️ pre-existing failures | ❌ needs attention
Reviewer: @<handle>
```

## Tips

- **Batch related findings:** If multiple CVEs affect the same package in the same repo, fix them all in one PR
- **Check existing PRs:** Before creating a fix, check if a Dependabot PR already exists for the same bump — if so, just review and merge it instead
- **Rock images:** Most Trivy findings in rocks are from base image packages. If the fix requires an Ubuntu base image update, flag it — this is an upstream dependency
- **Don't fix what's not broken:** If the vulnerable code path is not actually reachable in the project, document it as a suppression rather than making unnecessary changes
