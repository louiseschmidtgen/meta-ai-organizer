# Reusable Workflow SHA Cache

SHAs for reusable GitHub Actions workflows that `pin-actions.sh` cannot resolve automatically.
These are point-in-time snapshots — re-resolve via `git ls-remote` if repos have been updated.

## How to resolve a new workflow

```bash
GIT_TERMINAL_PROMPT=0 git ls-remote https://github.com/<org>/<repo>.git refs/heads/<branch>
```

Then replace in the workflow file:

```bash
sed -i.bak 's|org/repo/\.github/workflows/file.yaml@branch|org/repo/.github/workflows/file.yaml@<sha> # branch|g' <file>
rm -f <file>.bak
```

## Cache (last verified: 2026-04-07)

| Workflow                       | Ref     | SHA                                        |
| ------------------------------ | ------- | ------------------------------------------ |
| `canonical/k8s-workflows`      | `main`  | `6b24c265636d618fb98d5f56231c5581a1b429ab` |
| `canonical/operator-workflows` | `main`  | `27f280ed34b54bd9f65451dc966bfde701e84b62` |
| `canonical/craft-actions`      | `main`  | `9f9af048b247978a330f4e7cce3a3fcb8ca267b9` |
| `canonical/inclusive-naming`   | `main`  | `7aa0f7a606f182bd03a7adb28e0d710216101ca5` |
| `charmed-kubernetes/workflows` | `main`  | `6ee58c37d404effad4598ce7b523dbaf0cb99285` |
| `github/codeql-action`         | `v3`    | `3b1a19a80ab047f35cbb237b5bd9bdc1e14f166c` |
| `github/codeql-action`         | `v4`    | `d4b3ca9fa7f69d38bfcd667bdc45bc373d16277e` |
| `canonical/charming-actions`   | `2.7.0` | `1753e0803f70445132e92acd45c905aba6473225` |
| `canonical/charming-actions`   | `2.6.3` | `934193396735701141a1decc3613818e412da606` |

**Note:** `codeql-action` subpaths (`/init`, `/analyze`, `/autobuild`) share the same SHA as the base action.
