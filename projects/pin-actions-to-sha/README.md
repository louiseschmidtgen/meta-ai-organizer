# Pin GitHub Actions to SHA

Pin all GitHub Actions references to full commit SHAs across Canonical
Kubernetes repositories, replacing mutable tag references (e.g. `@v4`)
with immutable SHA pins (e.g. `@<full-sha> # v4`).

## Background

Mutable tags (`@v3`, `@v4`, `@latest`) can be moved by upstream
maintainers — or by an attacker who compromises an action's repository.
Pinning to a full 40-character commit SHA ensures that workflows always
run exactly the code that was reviewed and approved.

This is a supply-chain security hardening measure recommended by:

- [GitHub's own security guidance](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions#using-third-party-actions)
- [OpenSSF Scorecard](https://github.com/ossf/scorecard) (`Pinned-Dependencies` check)
- [StepSecurity](https://app.stepsecurity.io/) hardening tool

## Example

Before:

```yaml
- uses: actions/checkout@v4
```

After:

```yaml
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4
```

The trailing comment preserves the human-readable version for easy
identification and future updates.

## Tooling

[StepSecurity's `secure-actions`](https://app.stepsecurity.io/) can
automatically pin all actions in a workflow file. Alternatively, you can
use the [`pin-github-action`](https://github.com/mheap/pin-github-action)
CLI:

```bash
# Install
npm install -g pin-github-action

# Pin all actions in a workflow file
pin-github-action .github/workflows/ci.yaml
```

Or manually look up the SHA on GitHub:

```bash
# Get the SHA for a tag
git ls-remote --tags https://github.com/actions/checkout v4
```

## Rollout Plan

### Priority repositories

| #   | Repository                                                      | Status                                                                     |
| --- | --------------------------------------------------------------- | -------------------------------------------------------------------------- |
| 1   | [k8s-snap](https://github.com/canonical/k8s-snap)               | � [PR #2491](https://github.com/canonical/k8s-snap/pull/2491) (bschimke95) |
| 2   | [k8s-operator](https://github.com/canonical/k8s-operator)       | 🔲 To do                                                                    |
| 3   | [k8s-dqlite](https://github.com/canonical/k8s-dqlite)           | 🔲 To do                                                                    |
| 4   | [k8sd](https://github.com/canonical/k8sd)                       | 🔲 To do                                                                    |
| 5   | [cluster-api-k8s](https://github.com/canonical/cluster-api-k8s) | 🔲 To do                                                                    |
| 6   | [microk8s](https://github.com/canonical/microk8s)               | 🔲 To do                                                                    |

### Broader rollout

After the priority repos are done, extend to all repositories in
`../Repositories/repositories.yaml`.

## PR Template

Use a consistent commit message and PR body:

**Branch:** `KU-5612/pin-actions-to-sha`

**Commit:** `ci: pin GitHub Actions to commit SHAs`

**PR body:**

```markdown
## Summary

Pin all GitHub Actions to full commit SHAs for supply-chain security
hardening, replacing mutable tag references.

## Why

Mutable tags (e.g. `@v4`) can be moved by upstream maintainers or by
an attacker who compromises an action repo. Pinning to a SHA ensures
workflows always run exactly the reviewed code.

This follows GitHub's own security hardening guidance and improves
our OpenSSF Scorecard rating.

## What this PR does

- Replaces all `uses: <action>@<tag>` references with
  `uses: <action>@<sha> # <tag>`
- No functional changes — same action versions, just pinned

## How to verify

All CI checks should pass identically since the same action
versions are used.
```

## Files

- `context/` — Background and implementation notes
- `priority-repos.yaml` — Machine-readable list of priority repositories
