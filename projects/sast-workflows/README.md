# SAST Workflows Project

Implement Static Application Security Testing (SAST) scanning workflows across
Canonical Kubernetes repositories, as recommended by the security team.

## Background

Security researchers have identified severe vulnerabilities — including remote
code execution — in our public codebases. In most cases, the vulnerability was
easily discovered (i.e., an open-source SAST tool immediately flagged the root
cause with no special configuration).

**Company policy:** Every repository must implement a SAST scanning workflow.

> Note: This is recommended even if the repository is onboarded to SSDLC;
> TIOBE has missed some recent vulnerabilities.

## Tools

| Tool                                             | Scope           | License                     | Notes                                                   |
| ------------------------------------------------ | --------------- | --------------------------- | ------------------------------------------------------- |
| [Bandit](https://bandit.readthedocs.io/)         | Python-specific | OSS                         | Catches common Python security anti-patterns            |
| [Semgrep](https://semgrep.dev/)                  | Multi-language  | OSS CLI (no account needed) | Community rulesets for Python, GitHub Actions, Go, etc. |
| [OpenGrep](https://github.com/opengrep/opengrep) | Multi-language  | OSS (Semgrep fork)          | Fully open-source alternative                           |
| [CodeQL](https://codeql.github.com/)             | Multi-language  | Partly OSS (by GitHub)      | Deep semantic analysis, SARIF output                    |

## Rollout Plan

### V1 — Pilot (2 repositories)

| Repository                                        | Bandit                                                        | Semgrep                                                       | Status  |
| ------------------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------- | ------- |
| [k8s-snap](https://github.com/canonical/k8s-snap) | ✅ [PR #2466](https://github.com/canonical/k8s-snap/pull/2466) | ✅ [PR #2468](https://github.com/canonical/k8s-snap/pull/2468) | Merged  |
| [k8sd](https://github.com/canonical/k8sd)         | N/A (Go-only repo)                                            | 🔲 To do                                                       | Pending |

> k8sd is a pure Go repository — Bandit (Python-only) does not apply.
> Semgrep with Go + GitHub Actions rulesets is the primary SAST tool here.

### V2 — Broader rollout

Roll out to remaining repositories listed in `../Repositories/repositories.yaml`.

## Reference Implementation

The k8s-snap PRs serve as the reference:

- **Bandit (Python):** Added to existing `python-lint` CI job via tox environments.
  Blocks on HIGH severity only (`-lll` flag).
- **Semgrep:** Standalone workflow (`.github/workflows/semgrep.yaml`).
  Advisory-only initially; results uploaded to GitHub Security tab via SARIF.

## Repository Layout

```
projects/sast-workflows/
├── PROGRESS.yaml              # Master tracking for all 172 repos
├── README.md                  # This file
├── context/                   # Background docs, policy references
├── scripts/                   # Automation scripts (see below)
├── templates/
│   ├── workflows/
│   │   ├── semgrep.yaml       # Semgrep workflow template
│   │   └── bandit.yaml        # Bandit workflow template
│   └── lock-files/
│       ├── requirements-semgrep.{in,txt}
│       └── requirements-bandit.{in,txt}
└── workflows/k8sd/            # Ready-to-PR workflow files for k8sd
```

## Scripts

All scripts live in `scripts/` and are designed to run in sequence.

### 1. `process-repos.sh` — Add workflows to cloned repos

```bash
bash scripts/process-repos.sh <repo-list.txt> <clone-dir> <results-file>
```

Reads a list of repos (one `org/repo` per line), checks each clone in
`<clone-dir>`, creates branch `KU-5612/sast-workflows`, copies workflow
templates + pinned lock files, adds bandit config to `pyproject.toml` for
Python repos, and commits. Outputs `OK:` / `SKIP:` lines to `<results-file>`.

**Skips:** repos that already have a semgrep workflow, repos with no `.github/`
directory, repos already processed.

### 2. `push-and-create-prs.sh` — Push branches and open PRs

```bash
bash scripts/push-and-create-prs.sh <results-file> <clone-dir> <pr-output-file>
```

Reads the `OK:` lines from step 1, pushes each branch, and creates a PR via
`gh pr create`. Uses a Python-specific PR body (semgrep + bandit) or a
non-Python body (semgrep only) depending on whether `bandit.yaml` exists.
Outputs `PR:org/repo:url` lines.

### 3. `check-ci-status.sh` — Verify CI pass/fail

```bash
bash scripts/check-ci-status.sh <prs-file>
```

Reads the `PR:` lines, runs `gh pr checks` for each, and reports semgrep/bandit
status. Prints a summary table and lists repos with failed bandit runs.

### 4. `get-bandit-findings.sh` — Extract findings from failed runs

```bash
bash scripts/get-bandit-findings.sh <org/repo> [<org/repo> ...]
```

For each repo, fetches the latest failed bandit GitHub Actions run log and
extracts `file:line:CODE` tuples (e.g. `src/charm.py:93:B701`). Output is used
to drive `fix-bandit-findings.sh`.

### 5. `fix-bandit-findings.sh` — Add `# nosec` annotations and create fix PRs

```bash
bash scripts/fix-bandit-findings.sh <clone-dir> <fix-pr-file> \
  "org/repo" "file:line:CODE" ["file:line:CODE" ...]
```

Creates branch `KU-5612/fix-bandit-findings` off the default branch, adds
`# nosec <CODE>` to each flagged line, commits, pushes, and opens a PR. The
PR body includes a table mapping each finding code to its rationale.

Can also be sourced to call `fix_repo()` in a wrapper.

### 6. `update-progress.sh` — Sync PROGRESS.yaml

```bash
bash scripts/update-progress.sh <results-file> <prs-file> <fix-prs-file> <clone-dir>
```

Reads outputs from the previous scripts and updates `PROGRESS.yaml` with PR
URLs, status changes (`todo` → `pr-open`, `no-github-dir`, etc.), and
bandit-fix-pr links.

## Rollout Results

| Metric                   | Count |
| ------------------------ | ----- |
| Total repositories       | 172   |
| SAST PRs created         | 134   |
| No `.github/` directory  | 30    |
| No push access (403)     | 5     |
| Semgrep exists / skipped | 2     |
| Bandit fix PRs created   | 37    |

All 134 semgrep workflows pass. Bandit passes after fix PRs are merged.

## Bandit Findings Audit

The 37 bandit fix PRs were audited to evaluate whether each `# nosec`
annotation is justified. Findings are grouped by bandit code.

### B324 — `hashlib.md5()` (16 PRs)

Repos: aws-k8s-storage, bundle, charm-aws-cloud-provider,
charm-azure-cloud-provider, charm-calico, charm-cilium, charm-containerd,
charm-gcp-cloud-provider, charm-kubernetes-control-plane,
charm-kubernetes-worker, gcp-k8s-storage, layer-easyrsa, layer-etcd,
layer-kubernetes-common, nvidia, vsphere-cloud-provider.

**Verdict: nosec justified.** All instances use MD5 for non-security purposes
— content-addressable config hashing to detect changes, not cryptographic
integrity. The hash is compared against a previous hash of the same content
to trigger restarts when config changes. No attacker-controlled input.

### B501 — `requests.get(verify=False)` (11 PRs)

Repos: charm-kata, charm-kube-ovn, charm-kube-virt,
charm-kubeapi-load-balancer, charm-kubernetes-control-plane,
charm-kubernetes-worker, charm-volcano, kube-state-metrics-operator,
interface-k8s-service, layer-kubernetes-common, microk8s.

**Verdict: nosec justified (with caveat).** All instances are internal cluster
API calls (e.g. `https://localhost:16443`, kubelet health checks, or
cluster-internal service endpoints) where the charm is already running on
a trusted node. TLS verification against a self-signed CA would be ideal
but is a larger refactor. The microk8s instances are known tech debt documented
in `microk8s/scripts/wrappers/`.

### B701 — Jinja2 `autoescape=False` (13 PRs)

Repos: charm-cilium, charm-containerd, charm-kubernetes-control-plane,
charm-kubernetes-worker, cdk-shrinkwrap, kubernetes-docs, layer-etcd,
layer-kubernetes-common, ops-reactive-interface, serialized-data-interface,
mayastor-control-plane, mayastor, loadbalancer-interface.

**Verdict: nosec justified.** All instances render YAML, INI, shell, or CNI
config templates — never HTML served to browsers. Jinja2 autoescape is an
HTML-injection defence; it is actively harmful for non-HTML output because it
would mangle YAML values and shell variables.

### B602 — `subprocess(shell=True)` (5 PRs)

Repos: charm-kata, charm-kubernetes-control-plane, microk8s,
microk8s-community-addons, rawfile-localpv.

- **charm-kata, charm-kubernetes-control-plane, microk8s,
  microk8s-community-addons:** nosec justified. Commands are string literals
  or constructed from controlled snap/charm config — no user-supplied input
  reaches the shell.
- **rawfile-localpv:** **nosec NOT justified.** Six instances in production CSI
  driver code use f-string interpolation (`f"rawfile … {img_file}"`) piped
  through `shell=True`. This is a genuine shell injection risk if volume names
  are attacker-influenced. **Recommended fix:** refactor to list-form
  `subprocess.run([...])` calls.

### B202 — `tarfile.extractall()` (5 PRs)

Repos: keystone-k8s-auth-operator, kube-galaxy-test,
microk8s-core-addons, microk8s-community-addons, loadbalancer-interface.

- **kube-galaxy-test:** Properly fixed with `filter="data"` parameter (Python
  3.12+) — no nosec needed. This is the correct approach.
- **keystone-k8s-auth-operator, microk8s-core-addons,
  microk8s-community-addons, loadbalancer-interface:** nosec applied but
  `filter="data"` would be a better fix (guards against path traversal in
  tar entries). All extract from trusted upstream release tarballs, so risk
  is low but not zero.

### B103 — `os.chmod(path, 0o777)` (1 PR)

Repo: microk8s-core-addons.

**Verdict: nosec justified (vendored code).** The 0o777 chmod is in
`addons/prometheus/client_python/`, a vendored copy of the upstream
`prometheus_client` library. Fixing it in-tree would diverge from upstream;
filing an upstream issue is the better path.