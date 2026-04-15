# Lessons Learned

Patterns and fixes discovered during the mx-workflows rollout.

## `permissions: {}` requires explicit `contents: read`

Setting `permissions: {}` at the workflow level drops **all** default permissions,
including `contents: read`. Self-hosted runners then fail with
`remote: Repository not found` because they cannot fetch private repos.

**Fix:** Add `permissions: contents: read` at the job level for every job that
checks out code.

## `go-version-file` beats hardcoded versions

Berkay's `install-go` composite action originally hardcoded `go-version: "1.24.9"`
with `GOTOOLCHAIN=local`. When a repo's `go.mod` requires a newer Go version
(e.g. 1.25.0), CI fails with:

```
go.mod requires go >= 1.25.0 (running go 1.24.9; GOTOOLCHAIN=local)
```

**Fix:** Change from `go-version` to `go-version-file: go.mod` so the version
always matches what the repo declares.

## `persist-credentials: false` — skip vendor workflows

Vendor workflows run `git push` to commit `vendor/` and `go.sum` changes.
They need the checkout credentials to push. All other workflows should set
`persist-credentials: false`.

## `upload-artifact` / `download-artifact` tokens

These actions use an internal Actions runtime token, not `GITHUB_TOKEN`.
No additional permissions are needed in the workflow.

## `${{ inputs.* }}` in `with:` is safe

Using `${{ inputs.* }}` in a `with:` block is safe (structured YAML data, not
shell interpolation). It's only dangerous in `run:` blocks.
