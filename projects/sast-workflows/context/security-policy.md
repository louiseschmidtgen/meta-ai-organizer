# Security Policy Context

## Requirement

> Implement a SAST scanning workflow for your repository.

This is recommended even if the repository is onboarded to SSDLC; TIOBE has
missed some recent vulnerabilities.

## Motivation

Security researchers have identified severe vulnerabilities — including remote
code execution — in our public codebases. In most cases, the vulnerability was
easily discovered (i.e., an open-source SAST tool immediately flagged the root
cause with no special configuration).

## Recommended OSS Tools

1. **Bandit** — Python-specific SAST
2. **Semgrep** (and OpenGrep, an OSS fork) — Multi-language, community rulesets
3. **CodeQL** — By GitHub, partly open source, deep semantic analysis

## Implementation Guidelines

- Start advisory-only (don't block PRs immediately)
- Upload results as SARIF to GitHub Security tab for visibility
- Fix pre-existing findings in follow-up PRs
- Once clean, enable blocking mode (`--error` flag for Semgrep, `-lll` for Bandit)
- Pin tool versions for reproducibility
