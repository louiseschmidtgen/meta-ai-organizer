# k8s-snap Reference Implementation

## Overview

- **Repo:** <https://github.com/canonical/k8s-snap>
- **Languages:** Go, Python, Shell
- **PRs implemented:**
  - Bandit: [PR #2466](https://github.com/canonical/k8s-snap/pull/2466) — merged 2026-03-31
  - Semgrep: [PR #2468](https://github.com/canonical/k8s-snap/pull/2468) — merged 2026-03-31

## Bandit (PR #2466)

**Scope:** Python code in `tests/integration/`, `ci/`, `build-scripts/`, `docs/tools/`

**What was done:**
- Added `bandit[toml]==1.7.10` to `tests/integration/requirements-dev.txt` and `ci/requirements-ci.txt`
- Added `[testenv:bandit]` tox environments in `tests/integration/tox.ini` and `ci/tox.ini`
- Added Bandit scan step to existing `python-lint` job in `.github/workflows/lint_and_integration.yaml`
- Added `pyproject.toml` with `[tool.bandit]` config (exclude `.tox` dirs)

**Behavior:**
- CI blocks only on HIGH severity (`-lll` flag)
- LOW/MEDIUM reported but do not fail the build

**Scan results at merge time:**
- 9392 lines scanned
- Low: 205, Medium: 50, High: 0

## Semgrep (PR #2468)

**Scope:** All files in repo; rulesets: `p/python`, `p/github-actions`

**What was done:**
- Created standalone `.github/workflows/semgrep.yaml`
- Uses `pip install semgrep==1.156.0` (no account/token needed)
- Runs `semgrep scan` with `--sarif` output
- Uploads SARIF to GitHub Security tab via `github/codeql-action/upload-sarif@v3`

**Triggers:**
- Push to `main` and `release-*` branches
- Pull requests (excluding `docs/**`)

**Behavior:**
- Advisory only — findings appear in Security tab but do not block PRs
- 16 pre-existing shell injection findings identified (to be fixed separately)

**Follow-up:**
- Fix pre-existing shell injection findings
- Once fixed, enable `--error` flag to make Semgrep blocking
