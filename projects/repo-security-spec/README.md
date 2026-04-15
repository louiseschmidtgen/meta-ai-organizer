# Repository Security Specification

Best practices for securing GitHub repositories across Canonical Kubernetes.

## Abstract

This specification lays out the Kubernetes team's best practices for securing GitHub repositories.

## Rationale

Our value proposition to VMware is security maintenance and long-term support of upstream repositories (etcd, containerd, CoreDNS, etc). Adhering to the best practices laid out in this specification ensures our commitment to that promise.

## Specification

### Repository Settings

| Setting                             | Rationale                                                                                                                                                                    |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Branch Protection**               | Require PR reviews before merge, require status checks to pass, prevent force pushes and branch deletion. Stops single-actor compromise of `main`.                           |
| **Verified Commit Messages**        | Require GPG/SSH signed commits. Prevents commit author impersonation and ensures traceability.                                                                               |
| **CodeQL Analysis**                 | Identify vulnerabilities and errors in code via static analysis on every PR.                                                                                                 |
| **Secret Scanning**                 | Detect accidentally committed credentials, tokens, and private keys. Enable push protection to block secrets before they land.                                               |
| **Dependabot**                      | Automated alerts and PRs for known-vulnerable dependencies. Reduces time-to-patch for CVEs in transitive deps.                                                               |
| **CODEOWNERS**                      | Enforce review from domain experts on sensitive paths (`.github/`, security configs, crypto).                                                                                |
| **Security Policy (`SECURITY.md`)** | Gives external reporters a channel for responsible disclosure. Without it, vulnerabilities get filed as public issues.                                                       |
| **Repository Rulesets**             | Successor to branch protection rules. More granular, supports tag protection, and can be applied org-wide. Use alongside or instead of legacy branch protection.             |
| **Dependency Review**               | Blocks PRs that introduce known-vulnerable dependencies — Dependabot only alerts after merge. This is the shift-left gate. Free for public repos, requires GHAS for private. |
| **Dependabot Version Updates**      | Configure `dependabot.yml` for proactive version bumps. Keeps deps current so security patches apply cleanly.                                                                |
| **Dependency Graph / SBOM Export**  | SPDX-compatible SBOM generation. Required for compliance audits and supply-chain transparency.                                                                               |
| **Disable Unused Features**         | Turn off wiki, projects, discussions if unused. Each enabled feature is additional attack surface.                                                                           |

### Writing Secure GitHub Actions

| Action                                                       | Rationale                                                                                                                                                                                                                                                                                                                                           |
| ------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Pin actions to full SHAs**                                 | Avoid compromise of the action. Know exactly which SHA was used in case of a vulnerability within the tool.                                                                                                                                                                                                                                         |
| **Top-level job permissions**                                | If no top-level permissions are set, GitHub grants all permissions by default. Set `permissions: {}` and add job-level permissions as needed.                                                                                                                                                                                                       |
| **Never interpolate untrusted values in `run:` blocks**      | Attacker-controlled inputs (`github.event.pull_request.title`, `github.event.issue.body`, `github.event.comment.body`, `github.head_ref`, `inputs.*`) injected via `${{ }}` into `run:` blocks enable arbitrary code execution. Always pass them as environment variables instead — the shell treats env vars as data, not code. See example below. |
| **Avoid `pull_request_target` with PR head checkout**        | Combines write permissions with untrusted code. If checkout of the PR head is needed, run it in a separate unprivileged job.                                                                                                                                                                                                                        |
| **Use `actions/checkout` with `persist-credentials: false`** | Prevents the `GITHUB_TOKEN` from being persisted in the local git config, reducing scope if a later step is compromised.                                                                                                                                                                                                                            |
| **Pin runner images**                                        | Use specific Ubuntu versions (`ubuntu-24.04`) not `ubuntu-latest`. Avoids unexpected behaviour when GitHub rolls the image.                                                                                                                                                                                                                         |
| **Artifact attestations (SLSA provenance)**                  | Use `actions/attest-build-provenance` to generate cryptographic proof of where and how a build artifact was produced. Critical for supply-chain trust of rocks/snaps. Free on public repos.                                                                                                                                                         |


This applies to **all** user-controlled context values: `github.event.*`, `github.head_ref`, `inputs.*`, and any value that flows through issue bodies, commit messages, or branch names.

### Dependency Management

| Action                                   | Rationale                                                                                                    |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Lock files committed**                 | Pin exact dependency versions. Ensures reproducible builds and prevents silent upgrades.                     |
| **No `curl \| bash` installs**           | Unauthenticated remote code execution. Use package managers or vendored binaries with checksum verification. |
| **Verify checksums on binary downloads** | Prevents MITM or compromised mirror from injecting malicious binaries.                                       |

### Secrets Handling

| Action                                           | Rationale                                                                                       |
| ------------------------------------------------ | ----------------------------------------------------------------------------------------------- |
| **No hardcoded credentials**                     | Secrets in code persist in git history forever. Use GitHub Secrets or external secret managers. |
| **Rotate tokens on exposure**                    | Any token that has been committed, even briefly, must be revoked immediately.                   |
| **Scope tokens to minimum required permissions** | A `contents: read` token cannot be used to push code if compromised.                            |
