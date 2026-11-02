# Cluster Foundation Design

The normative definition lives in the yass specs; start at `root.yass.yaml` or run
`yass list`. This doc holds what the specs can't: the shape at a glance, and why.

## Overview

A fresh cluster plus `clusters/<name>.yaml` goes through three layers, each gated on the
previous one being Synced and Healthy in Argo CD:

| Layer     | Installed by                   | Purpose                                 | Spec                  |
| --------- | ------------------------------ | --------------------------------------- | --------------------- |
| bootstrap | `helm install` (once)          | Cilium, Argo CD, seeded secrets         | `docs/spec/bootstrap` |
| core      | Argo CD, AppProject `core`     | Cluster works, is secure and observable | `docs/spec/core`      |
| platform  | Argo CD, AppProject `platform` | What applications consume               | `docs/spec/platform`  |

Providers: `eks`, `baremetal` (Talos), and `doks` (DigitalOcean). The project list, with chart, namespace, layer,
providers, and sync wave, is the `Catalog` design block in `root.yass.yaml`.

## Layer boundaries

**Core** is what every cluster needs to function, be secure, and be observable, whether
or not any application runs on it: networking, DNS, certificates, storage, node
autoscaling, admission policy, runtime security, secrets delivery, and metrics.
**Platform** is what applications consume: operators and tools that act on application
workloads or that teams opt into, such as Kafka, databases, VMs, migrations, promotion,
load testing, and autoscaling on app events.

Rule of thumb: if removing it breaks the cluster or an invariant other components rely on,
such as the default StorageClass, it's core. If removing it only takes away a capability
apps could use, it's platform.

How the boundary is enforced:

- **Ordering.** The platform layer doesn't start until every core Application is Synced
  and Healthy. Core's guarantees (all Healthy, exactly one default StorageClass, wave 1
  CRDs and webhooks established) are the platform layer's input, and it doesn't re-check
  them (`Core::RETURN` → `Platform::INPUT`).
- **Permissions.** AppProject `core` may create any cluster-scoped resource. AppProject
  `platform` is limited to CRDs, ClusterRoles, ClusterRoleBindings, webhook
  configurations, and Namespaces.
- **Core-only clusters.** `coreOnly: true` stops after core, for clusters that serve no
  apps.

## Optional components

Optionality works the same way in every layer. Each catalog entry is one of:

| Kind     | Default       | Cluster values               | Entries                                                                                                                                                                                                                                                                                                                                                  |
| -------- | ------------- | ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Required | Installed     | Can't be turned off          | Everything not listed below                                                                                                                                                                                                                                                                                                                              |
| Optional | Installed     | `disable: [name]` removes it | Every platform component except the identity add-ons, `longhorn`, `local-path-provisioner`                                                                                                                                                                                                                                                               |
| Opt-in   | Not installed | `enable: [name]` adds it     | `zot` (bare metal pull-through cache), `rook` (bare metal Ceph), `csi-driver-nfs` and `democratic-csi` (bare metal NFS and iSCSI), `falco`, `tetragon`, `argocd-agent`, `argocd-agent-principal`, `authentik`, `keycloak`, `oauth2-proxy`, `kube-prometheus-stack` or `victoria-metrics-k8s-stack`, `grafana`, `arc` (GitHub Actions runners), `openbao` |

Naming anything else in either list is rejected. A name the provider doesn't offer, such as
`kubevirt` on EKS, is accepted and does nothing.

- **Storage.** On bare metal, Longhorn is the default. With `disable: [longhorn]`,
  local-path-provisioner becomes the default StorageClass instead (node-local, no
  replication). With both disabled, `defaultStorageClass` names one you provide, and
  bootstrap checks it exists and is the only default. Either way, core still guarantees
  exactly one default StorageClass to the platform layer. `enable: [rook]` runs Rook Ceph
  (block pool only, three-way replicated, over every unused node device) as the default
  instead; it requires `disable: [longhorn]`.
- **Extra storage (bare metal).** `enable: [csi-driver-nfs]` with `nfs.server` and `nfs.share`
  adds a non-default `nfs-csi` StorageClass. `enable: [democratic-csi]` adds a non-default
  `iscsi` StorageClass against TrueNAS, a ZFS host, or Synology; `democraticCsi.driver` names the
  driver and its whole config is one `op://` reference. Nodes need the Talos `iscsi-tools` extension.
- **Identity.** `authentik`, `keycloak`, and `oauth2-proxy` are opt-in platform add-ons.
  Authentik and Keycloak use an external Postgres (`<name>.postgresHost`); oauth2-proxy signs
  in through `oauth2Proxy.issuerUrl`. Secrets come from 1Password. None is exposed or configured
  beyond install; add routes, realms, and clients per cluster.
- **Metrics.** `enable: [kube-prometheus-stack]` or `enable: [victoria-metrics-k8s-stack]`
  (never both) installs a full metrics stack in `monitoring`, with the prometheus-operator CRDs
  and a ServiceMonitor for core's kube-state-metrics. `enable: [grafana]` adds Grafana with a
  datasource for whichever stack is on; its admin password comes from 1Password. See ADRs 65-66.
  With a stack on, core infrastructure (Cilium, Argo CD, cert-manager, external-secrets, storage,
  DNS, Karpenter, runtime inspection, kube-state-metrics) gets ServiceMonitors by default;
  `monitor.add` and `monitor.remove` adjust that per cluster. See ADR 68.
- **CI runners.** `enable: [arc]` with `arc.githubConfigUrl` installs Actions Runner Controller
  and one runner scale set named after the cluster (`runs-on: <clusterName>`), registered with a
  GitHub App from 1Password, in Kubernetes container mode, up to `arc.maxRunners` (default 5).
  Workflows that need a Docker daemon don't work there. See ADR 67.
- **Secrets manager.** `enable: [openbao]` with `secretRefs.openbaoSealKey` runs OpenBao as a
  three-replica Raft cluster that unseals itself with a static key from 1Password and
  self-initializes with only Kubernetes auth: get in with a token for the `openbao-admin`
  ServiceAccount and role `admin`. Apps read it through external-secrets. See ADR 69.
- **Runtime inspection.** Falco and Tetragon are opt-in on every provider; neither is
  installed unless named in `enable`.
- **Pull-through cache.** `enable: [zot]` with `pullThroughCacheIp` (an address in
  `lbIpPool`) runs zot as an on-demand mirror of Docker Hub, ghcr.io, quay.io,
  registry.k8s.io, public.ecr.aws, and gcr.io. `scripts/talos-registry-patch` renders the
  Talos mirror config that points nodes at it; Talos falls back to upstream if zot is down.
  On EKS, use an ECR pull-through cache configured outside the cluster instead.
- **Domain-gated.** external-dns (core) and kubechecks (platform) are installed only when
  `clusters/<name>.yaml` sets `domain`, since not every cluster owns a DNS zone.
- **Knock-on effects.** Disabling `kargo` drops its seeded Secret and its `secretRefs`. CDI
  goes with KubeVirt: disabling `kubevirt` also removes `cdi`, and `cdi` can be disabled alone.
- **Provider scope is not optionality.** Projects that exist only for one provider (Karpenter
  on EKS, Longhorn on bare metal) are set by the catalog's providers, not by these lists.

Changes are verified by render tests (helm template, kubeconform, conftest Rego), API
tests (server-side dry-run against kwok), and a risk check that compares the rendered base
and head trees; see `docs/spec/verification`.

## Decisions

Decisions are recorded as ADRs in [`docs/adr/`](adr/), managed with
[adrs](https://github.com/joshrotenberg/adrs); see `AGENTS.md` for how to add one.

## Known gaps

- No backup tool (Velero dropped); no object storage on bare metal.
- No e2e tests yet; version upgrades are checked only by render, API, and risk tests.
- The risk check's Rego is unit-tested, but it hasn't yet run against a real risky base commit.
- KubeVirt and CDI come from a small community publisher; watch for lag behind upstream.
- Operator-created workloads (KubeVirt's virt-handler, database pods) aren't in any render, so only the dryrun Constraints see them.
- `argocd-initial-admin-secret` stays in the cluster until Argo CD SSO exists; deleting it now would lose admin access.
- Egress is unrestricted; tighten with Hubble data after audit mode.
- On doks there are no network policies and no WireGuard: DigitalOcean manages Cilium, so audit
  mode can't be turned on and policies would enforce immediately.
- argocd-agent's PKI (CA, server and client certificates, JWT key) is issued outside this project
  and stored in 1Password; whether the principal also needs the CA's private key is unverified
  until e2e.
- EKS paths, Longhorn, and KubeVirt can't be exercised locally.

## Planned

- **E2E on Talos.** Spin up Talos in Docker (`talosctl cluster create`) in CI, run
  bootstrap, core, and platform for the baremetal provider, and assert every Application
  reaches Synced and Healthy. Run it nightly, and on pull requests that change e2e-relevant
  paths, such as pins, bootstrap, or the cluster/ chart. Its main job is to catch version
  updates that break the stack. Expect Longhorn and KubeVirt to need host support or test
  overrides there; it gets specified once the approach is proven.
- **DOKS in e2e.** A disposable DOKS cluster per run is a cheap real-cloud e2e target for the
  `doks` provider, alongside the Talos-in-Docker run.
- **Rego for in-cluster behavior.** Reuse the conftest policies, or Gatekeeper
  constraints, to assert behavior on a running cluster as part of e2e.
