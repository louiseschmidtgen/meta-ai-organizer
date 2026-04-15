# Summary

**Project:** MX Workflows — Review, Clean-up and Unify
**Status:** In Progress (2/15 repos started)

Unify CI workflows across 15 MX source repositories. Each repo gets build, test,
vendor-check, and release workflows with security hardening (SHA-pinned actions,
least-privilege permissions, persist-credentials: false).

## Metrics

- Repos processed: 2 / 15
- PRs open: 1 (mx-containerd)
- PRs merged: 0

## Lessons Learned

- `permissions: {}` drops ALL permissions including `contents: read` — must add
  job-level `contents: read` for any job that checks out code
- Berkay's `install-go` action hardcodes Go 1.24.9 but some repos need 1.25.0+ —
  switched to `go-version-file: go.mod` to stay in sync automatically
- Self-hosted runners on internal repos need explicit token permissions to checkout
