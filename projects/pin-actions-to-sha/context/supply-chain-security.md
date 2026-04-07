# Supply-Chain Security — Pinning Actions

## Problem

GitHub Actions references using mutable tags (e.g. `@v4`, `@main`) are
vulnerable to supply-chain attacks:

1. **Tag hijacking:** An attacker compromises an action's repository and
   moves the tag to point at malicious code. All workflows using that
   tag immediately run the attacker's code.

2. **Tag mutability:** Even without compromise, action maintainers can
   update what a tag points to at any time. A `v4` today might not be
   the same `v4` tomorrow.

3. **Lack of auditability:** Without SHA pins, there is no way to verify
   exactly which code ran in a past workflow execution.

## Solution

Pin every `uses:` reference to a full 40-character commit SHA. Keep the
human-readable tag as a trailing comment:

```yaml
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4
```

This gives:

- **Immutability:** The SHA is a content-addressable hash; it cannot be
  changed without the hash changing.
- **Auditability:** Every workflow run is tied to an exact commit.
- **Readability:** The comment preserves the version for humans.

## References

- [GitHub: Security hardening for GitHub Actions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions#using-third-party-actions)
- [OpenSSF Scorecard — Pinned-Dependencies](https://github.com/ossf/scorecard/blob/main/docs/checks.md#pinned-dependencies)
- [SLSA Supply-chain Levels for Software Artifacts](https://slsa.dev/)
- [StepSecurity — Harden Runner](https://github.com/step-security/harden-runner)

## Common Actions and Their SHAs

Look up current SHAs before creating PRs. Here are some frequently used
actions (SHAs will need to be verified at PR time):

| Action | Tag | How to find SHA |
|--------|-----|-----------------|
| `actions/checkout` | `v4` | `git ls-remote https://github.com/actions/checkout v4` |
| `actions/setup-go` | `v5` | `git ls-remote https://github.com/actions/setup-go v5` |
| `actions/setup-python` | `v5` | `git ls-remote https://github.com/actions/setup-python v5` |
| `actions/upload-artifact` | `v4` | `git ls-remote https://github.com/actions/upload-artifact v4` |
| `github/codeql-action/*` | `v3` | `git ls-remote https://github.com/github/codeql-action v3` |

## Process per Repository

1. List all workflow files: `ls .github/workflows/*.yaml`
2. Extract all `uses:` lines: `grep -rn 'uses:' .github/workflows/`
3. For each action reference, look up the SHA for the current tag
4. Replace `@<tag>` with `@<sha> # <tag>`
5. Run CI to confirm no regressions
6. Open PR with consistent commit message
