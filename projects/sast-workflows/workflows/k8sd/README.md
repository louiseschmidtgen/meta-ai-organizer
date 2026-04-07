# k8sd — Semgrep SAST Workflow

Ready-to-PR workflow file for adding Semgrep SAST scanning to
[canonical/k8sd](https://github.com/canonical/k8sd).

## What's included

```
.github/workflows/semgrep.yaml
```

### Semgrep workflow

- **Rulesets:** `p/go` (Go security rules) + `p/github-actions` (shell
  injection detection in workflow files)
- **Triggers:** Push to `main` / `release-*`; PRs (excluding `docs/**`)
- **Output:** SARIF uploaded to GitHub Security tab
- **Mode:** Advisory-only (does not block PRs)
- **Tool version:** `semgrep==1.156.0` (pinned)

### Why no Bandit?

k8sd is a pure Go repository — there is no Python code to scan. Bandit is
Python-specific and does not apply.

## How to create the PR

```bash
# Clone the repo
git clone https://github.com/canonical/k8sd.git
cd k8sd

# Create a branch
git checkout -b add-semgrep-sast

# Copy the workflow file
cp <path-to-this-dir>/.github/workflows/semgrep.yaml \
   .github/workflows/semgrep.yaml

# Commit and push
git add .github/workflows/semgrep.yaml
git commit -m "ci: add Semgrep SAST scanning workflow"
git push origin add-semgrep-sast

# Open a PR against main
gh pr create \
  --title "ci: add Semgrep SAST scanning workflow" \
  --body "## Summary

Add Semgrep OSS SAST scanning for Go and GitHub Actions workflow files,
as recommended by the security team.

Uses the fully open-source Semgrep CLI — no account, token, or
subscription required.

## What this PR does

Creates \`.github/workflows/semgrep.yaml\` that runs Semgrep with
community rulesets:

- \`p/go\` — Go security rules (command injection, path traversal, crypto misuse, etc.)
- \`p/github-actions\` — GitHub Actions security rules (shell injection detection)

Results are uploaded to the GitHub Security tab via SARIF.

## Triggers

- Push to \`main\` and \`release-*\` branches
- Pull requests (excluding docs-only changes)

## Blocking behavior

This scan is advisory only for now — findings appear in the Security tab
but do not block PRs. Once pre-existing findings are triaged/fixed, the
\`--error\` flag can be enabled to make it blocking.

## Follow-up

- Triage pre-existing findings (if any)
- Enable \`--error\` flag to make Semgrep blocking
"
```

## Differences from k8s-snap implementation

| Aspect           | k8s-snap                         | k8sd                             |
| ---------------- | -------------------------------- | -------------------------------- |
| Semgrep rulesets | `p/python`, `p/github-actions`   | `p/go`, `p/github-actions`       |
| Bandit           | Yes (Python code present)        | No (pure Go repo)                |
| Workflow file    | `.github/workflows/semgrep.yaml` | `.github/workflows/semgrep.yaml` |
| Semgrep version  | `1.156.0`                        | `1.156.0`                        |
