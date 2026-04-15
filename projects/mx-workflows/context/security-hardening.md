# Security Hardening for GitHub Actions Workflows

Reference checklist for MX workflow PRs, based on GitHub security guides
and OpenSSF Scorecard requirements.

## Critical

### No untrusted values in `run:` blocks
Never use `${{ github.event.* }}`, `${{ github.head_ref }}`, or `${{ inputs.* }}`
directly in `run:` blocks. Pass via environment variables instead.

### Top-level `permissions: {}`
Drop all permissions by default. Add job-level permissions as needed.

## High

### Pin actions to full commit SHAs
Every `uses:` referencing an external action must use a full 40-char SHA
with a version comment:
```yaml
uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
```

### Avoid `pull_request_target` with write permissions
Combines write permissions with untrusted code. Use `pull_request` trigger instead.

## Medium

### `persist-credentials: false` on checkout
Prevents the GITHUB_TOKEN from being persisted in `.git/config`.
Exception: vendor workflows that need `git push`.

### Artifact attestations (SLSA provenance)
Add `actions/attest-build-provenance` to release workflows for supply-chain trust.
(Follow-up item, not blocking initial rollout.)

## Low

### Pin runner images
Use specific labels (e.g. `self-hosted-linux-amd64-noble-medium`) not `ubuntu-latest`.

## SHA Reference (current as of 2026-04-15)

| Action                      | SHA                                      | Version |
| --------------------------- | ---------------------------------------- | ------- |
| actions/checkout            | de0fac2e4500dabe0009e67214ff5f5447ce83dd | v6.0.2  |
| actions/setup-go            | 4a3601121dd01d1626a1e23e37211e3254c1c06c | v6.4.0  |
| actions/upload-artifact     | b7c566a772e6b6bfb58ed0dc250532a479d7789f | v6.0.0  |
| actions/download-artifact   | d3f86a106a0bac45b974a628896c90dbdf5c8093 | v4.3.0  |
| softprops/action-gh-release | 3bb12739c298aeb8a4eeaf626c5b8d85266b0e65 | v2.6.2  |
| docker/setup-buildx-action  | 8d2750c68a42422c14e847fe6c8ac0403b4cbd6f | v3.12.0 |
| docker/login-action         | c94ce9fb468520275223c153574b00df6fe4bcc9 | v3.7.0  |
| docker/metadata-action      | c299e40c65443455700f0fdfc63efafe5b349051 | v5.10.0 |
| docker/build-push-action    | 10e90e3645eae34f1e60eeb005ba3a3d33f178e8 | v6.19.2 |
