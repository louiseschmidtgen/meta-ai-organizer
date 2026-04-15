# Changelog

## 2026-04-15

- Project kickoff from Jira KU-5591
- Audited all 15 MX repos: catalogued existing workflows, actions, and security gaps
- Identified Berkay's `canonical/updated-workflows` branches across all 15 repos
- Created PR for mx-containerd: https://github.com/canonical/mx-containerd/pull/24
  - Based on Berkay's branch + security hardening (SHA pinning, permissions, persist-credentials)
  - Fixed stale Go version in install-go action (1.24.9 → go-version-file: go.mod)
  - Fixed missing contents:read on build and test jobs
- Started mx-opencontainers-runc (security hardening applied, pending PR)
