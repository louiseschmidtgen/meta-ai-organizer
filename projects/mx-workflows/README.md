# MX Workflows — Review, Clean-up and Unify

Review, clean up, and unify per-repository workflows (testing, builds, artifacts)
across all MX (Maintained eXtended) source repositories.

**Jira:** KU-5591
**Status:** In Progress
**Assignee:** Louise Schmidtgen

## Background

The MX source repositories are Canonical forks of upstream projects (containerd,
runc, etcd, kubernetes, etc.). Each repo needs custom CI workflows because:

1. Upstream workflows reference external GitHub Actions (supply-chain risk)
2. Upstream workflows don't use self-hosted runners
3. Upstream workflows contain CI we don't need
4. Maintaining upstream workflows per-repo is unsustainable

## Goals

1. Add unified **build**, **test**, and **vendor-check** workflows to all MX repos
2. Keep **release** workflows producing artifacts in upstream-compatible format
3. Apply security hardening: SHA-pinned actions, least-privilege permissions,
   `persist-credentials: false`
4. Remove broken sync workflows (mx-supervisor handles sync now)

## Reference

- **Pattern repo:** `canonical/mx-containernetworking-plugins`
- **Berkay's branch:** `canonical/updated-workflows` (exists on all 15 repos)
- **KGT manifest:** `canonical/kube-galaxy-test/manifests/smoketest.yaml`

## Repos (15 total)

| Repo                             | Upstream                             |
| -------------------------------- | ------------------------------------ |
| mx-containernetworking-plugins   | containernetworking/plugins          |
| mx-containerd                    | containerd/containerd                |
| mx-opencontainers-runc           | opencontainers/runc                  |
| mx-coredns                       | coredns/coredns                      |
| mx-etcd                          | etcd-io/etcd                         |
| mx-golang                        | golang/go                            |
| mx-k8s-autoscaler                | kubernetes/autoscaler                |
| mx-k8s-csi-external-attacher     | kubernetes-csi/external-attacher     |
| mx-k8s-csi-external-provisioner  | kubernetes-csi/external-provisioner  |
| mx-k8s-csi-external-resizer      | kubernetes-csi/external-resizer      |
| mx-k8s-csi-external-snapshotter  | kubernetes-csi/external-snapshotter  |
| mx-k8s-csi-livenessprobe         | kubernetes-csi/livenessprobe         |
| mx-k8s-csi-node-driver-registrar | kubernetes-csi/node-driver-registrar |
| mx-k8s-sigs-cri-tools            | kubernetes-sigs/cri-tools            |
| mx-kubernetes                    | kubernetes/kubernetes                |

## Security Checklist (per repo)

- [ ] All external actions pinned to full commit SHAs
- [ ] `permissions: {}` at workflow top level
- [ ] Job-level permissions: only what's needed
- [ ] `persist-credentials: false` on checkout (except vendor push)
- [ ] No `${{ }}` expressions in `run:` blocks
- [ ] No `pull_request_target` with write permissions
- [ ] Artifact attestations (follow-up, not blocking)
