# Kubernetes Infrastructure

Foundational infrastructure for EKS, bare-metal (Talos), and DigitalOcean (DOKS) Kubernetes
clusters, delivered by
Argo CD. One values file per cluster; everything else is shared and pinned.

## How it works

A cluster comes up in three layers, each waiting for the one before it to be Synced and Healthy:

| Layer     | What                                                        | Installed by                      |
| --------- | ----------------------------------------------------------- | --------------------------------- |
| bootstrap | Cilium (CNI) and Argo CD                                    | `scripts/bootstrap-cluster`, once |
| core      | What every cluster needs: DNS, certs, storage, policy, etc. | Argo CD, AppProject `core`        |
| platform  | What applications use: Kafka, databases, VMs, Kargo, etc.   | Argo CD, AppProject `platform`    |

- **`cluster/`** is a Helm chart. `cluster/values.yaml` is the catalog: every project with its chart,
  pinned version, namespace, layer, providers, and sync wave. The chart turns the catalog plus a
  cluster's values into Argo CD Applications.
- **`clusters/<name>.yaml`** holds the only per-cluster settings: provider (`eks`,
  `baremetal`, or `doks`), API endpoint, domain, `disable` list, and `op://` references for secrets.
- **`scripts/bootstrap-cluster`** installs Cilium and Argo CD, seeds secrets from 1Password, and applies a single
  `cluster` root Application. From then on Argo CD manages everything, including itself.
- **Renovate** keeps the catalog's versions current (after 7 days of stability); CI checks every
  change before it merges.

The specs in [`root.yass.yaml`](root.yass.yaml) and [`spec/`](spec/) are the contract the code
is built against; [`docs/design.md`](docs/design.md) explains the decisions behind them.

## Layout

| Path                      | What                                                                                           |
| ------------------------- | ---------------------------------------------------------------------------------------------- |
| `cluster/`                | App-of-apps chart; `values.yaml` is the catalog, `values.schema.json` its shape                |
| `clusters/`               | One values file per cluster ([`spec/values`](spec/values.yass.yaml))                           |
| `scripts/`                | Every entry point: `bootstrap`, `test`, `cibuild`, `bootstrap-cluster`, and the tools they use |
| `policies/`               | Rego for cluster values, render rules, and risky-change checks, with tests                     |
| `tests/`                  | Chart tests (`tests/chart/`), bats tests, stubs, and fixtures                                  |
| `root.yass.yaml`, `spec/` | The specs                                                                                      |
| `archive/`                | The previous layout, kept for reference; not deployed or tested                                |

## Setup

Everything runs through [mise](https://mise.jdx.dev), which installs every other tool at the
version pinned in `mise.toml` (Helm, kubectl, yq, conftest, prek, talosctl, and the rest). Install
mise first, then install the tools and git hooks:

```bash
scripts/bootstrap
```

## Bring up a cluster

1. Start from a fresh cluster. On Talos, disable kube-proxy and flannel in the machine config.
2. Write its values file, starting from a fixture; secrets are `op://` references, never values:

   ```bash
   cp tests/clusters/baremetal.yaml clusters/<name>.yaml   # or tests/clusters/eks.yaml
   ```

3. Point kubectl at the cluster, sign in to the [1Password CLI](https://developer.1password.com/docs/cli/)
   (`op`, installed separately so it works with the 1Password app), and run:

   ```bash
   scripts/bootstrap-cluster clusters/<name>.yaml
   ```

   It validates the values, installs Cilium and Argo CD, seeds secrets, hands over to Argo CD,
   then waits up to 30 minutes per layer and names any Application that isn't healthy
   (`--no-wait` returns after handover). It's safe to re-run.

**Talos installing Cilium itself:** run `scripts/talos-cilium-patch clusters/<name>.yaml`
and apply the patch to the machine config; bootstrap then skips Cilium and Argo CD adopts it.
Remove the inline manifest afterwards so `talosctl upgrade-k8s` can't roll back later upgrades.

## Common changes

- **Turn components on or off** per cluster, the same way in every layer: `disable: [name]`
  removes an optional component, `enable: [name]` adds an opt-in one. On bare metal,
  `disable: [longhorn]` switches storage to local-path-provisioner.
- **Argo CD agent:** `enable: [argocd-agent]` with `argocdAgent.principalAddress` reports a
  cluster's Argo CD to a hub; the hub sets `enable: [argocd-agent-principal]`. Certificates are
  `op://` references.
- **Pull-through cache (bare metal):** `enable: [zot]` plus `pullThroughCacheIp`, then apply
  `scripts/talos-registry-patch clusters/<name>.yaml` to the Talos machine config.
- **Upgrade a project:** Renovate opens the PR; to do it by hand, bump `version` in
  `cluster/values.yaml`.
- **Add a project:** add a catalog entry to `cluster/values.yaml` and to the `Catalog` table in
  `root.yass.yaml`, add any per-project rules to the spec under `spec/`, and update the expected
  Applications in `tests/chart/layers_test.yaml`.

## Testing

Everything runs through prek:

```bash
prek run --all-files                       # fast: format, lint, specs, Rego, chart, and bats tests
prek run --all-files --hook-stage manual   # render every fixture, kwok API dry-run (Docker), risk check
```

Commits run the fast hooks; CI (`.github/workflows/ci.yaml`, job Lint/Test) runs both.
