# Cluster Foundation Design

The normative definition lives in the yass specs; start at `root.yass.yaml` or run
`yass list`. This doc holds what the specs can't: the shape at a glance, and why.

## Overview

A fresh cluster plus `clusters/<name>.yaml` goes through three layers, each gated on the
previous one being Synced and Healthy in Argo CD:

| Layer | Installed by | Purpose | Spec |
|---|---|---|---|
| bootstrap | `helm install` (once) | Cilium, Argo CD, seeded secrets | `spec/bootstrap` |
| core | Argo CD, AppProject `core` | Cluster works, is secure and observable | `spec/core` |
| platform | Argo CD, AppProject `platform` | What applications consume | `spec/platform` |

Providers: `eks` and `baremetal` (Talos). The project list, with chart, namespace, layer,
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

- **Core is mandatory, except storage.** On bare metal, Longhorn is the default. With
  `disable: [longhorn]`, local-path-provisioner becomes the default StorageClass
  instead (node-local, no replication). With both disabled, `defaultStorageClass`
  names one you provide, and core checks it exists and is the only default. Either way,
  core still guarantees exactly one default StorageClass to the platform layer.
- **One exception, external-dns.** It's installed only when `clusters/<name>.yaml` sets
  `domain`, since not every cluster owns a DNS zone. Route53 on EKS, Cloudflare on bare
  metal, with its token seeded from 1Password.
- **Platform is on by default.** Opt out per cluster with `disable: [name, ...]`. It
  accepts platform-layer names plus `longhorn` and `local-path-provisioner`; any other
  core, bootstrap, or unknown name is rejected. A platform name the provider doesn't offer, such as `kubevirt` on EKS, is
  accepted and does nothing.
- **Disabling has knock-on effects.** Disabling `kargo` drops its seeded Secret and its
  `secretRefs`. CDI goes with KubeVirt: disabling `kubevirt` also removes `cdi`,
  and `cdi` can be disabled alone.
- **Provider scope is not optionality.** Projects that exist only for one provider
  (Karpenter on EKS, Longhorn on bare metal) are set by the Catalog's providers column,
  not by `disable`.

Changes are verified by render tests (helm template, kubeconform, conftest Rego), API
tests (server-side dry-run against kwok), and a risk check that compares the rendered base
and head trees; see `spec/verification`.

## Decisions

| # | Decision | Why | Rejected |
|---|---|---|---|
| 1 | Spec with yass; manifests implemented against it | Spec is the reviewable contract; agents implement it repeatably | Hand-maintained manifests only |
| 2 | Spec requires exact pins; Renovate owns version numbers | Spec stays stable; git records what's deployed | Versions in spec (weekly churn); per-provider lockfile |
| 3 | Three layers: bootstrap, core, platform | Core can come up alone; platform relies on core's guarantees | Flat list |
| 4 | One Argo CD per cluster | Simplest, no cross-cluster credentials, small blast radius | Hub Argo with ApplicationSets |
| 5 | Helm app-of-apps with `clusters/<name>.yaml` | Familiar; one values file per cluster | Kustomize overlays; ApplicationSet + cluster secret |
| 6 | Cilium and Argo CD installed imperatively, then adopted by Argo CD | Pods can't schedule without a CNI | Argo CD installing Cilium |
| 7 | Cilium replaces the VPC CNI on EKS (ENI mode, no kube-proxy) | One networking model on both providers | Chaining with VPC CNI |
| 8 | Cilium LB-IPAM + L2/BGP on bare metal | No extra project | MetalLB |
| 9 | Charts only; config objects are a follow-up | Smallest working foundation; config needs per-cluster input | Charts + day-1 config |
| 10 | Exception: KubeVirt and CDI CRs installed | Operators deploy nothing without them | |
| 11 | Secrets seeded by bootstrap with `op read`; values carry only op:// refs | Nothing secret in git; one secret source | ESO ClusterSecretStore (counts as config) |
| 12 | EKS IAM via Pod Identity, created outside the cluster | No role ARNs in chart values | IRSA annotations |
| 13 | Crossplane, not ACK or kro | One control plane on both providers | ACK + kro; both with split ownership |
| 14 | Falco for runtime security | Useful default ruleset on day one | Tetragon (needs authored policies); revisit for enforcement |
| 15 | Gatekeeper for admission policy, no constraints in v1 | Requested; constraints are config | |
| 16 | Talos for bare metal | Immutable; handles reboots and upgrades itself, so no kured | k3s, RKE2, kubeadm |
| 17 | Longhorn in core on bare metal, optional | Default StorageClass there; peer of EBS CSI | Platform layer |
| 30 | Without Longhorn: local-path-provisioner, or bring your own StorageClass | Lighter clusters keep a default StorageClass; platform's input is unchanged | Dropping the storage guarantee |
| 31 | local-path-provisioner from upstream git at a release tag | No official Helm repo; community repackagings lag | containeroo and other community charts |
| 18 | KubeVirt via community chart (encircle360-oss) | Only publisher with both kubevirt and cdi charts | Kustomize remote URLs; vendored manifests |
| 19 | Atlas for schema migrations | Versioned and declarative, lints destructive changes | SchemaHero |
| 20 | Kargo per cluster, promoting within that cluster only | Fits Argo-per-cluster without a management cluster | Central Kargo control plane |
| 21 | Platform components default on, per-cluster `disable` list | Clusters stay uniform unless stated | Opt-in list |
| 22 | external-dns optional (needs `domain`); Route53 on EKS, Cloudflare on bare metal | Not every cluster owns a zone | |
| 23 | Strimzi and OpenEverest on both providers | Spec states what's installed, not what apps must use; MSK/RDS stay an app choice | Bare metal only |
| 24 | Render-tier schemas generated from the rendered CRDs, then the CustomResourceDefinition/catalog at a pinned tag as fallback; the API tier is authoritative | Exact match to our pins; the catalog covers CRDs that operators create at runtime | Catalog only (tracks latest CRDs, not our pins) |
| 25 | Argo CD Lua health check for child Applications | Without it, app-of-apps sync waves don't wait for child health | |
| 26 | CI renders with the Helm and Kustomize versions bundled in the pinned Argo CD | A render that passes only with other versions proves nothing | Latest tools |
| 27 | PR risk check compares rendered base and head trees | Catches data-loss and breaking transitions, especially in Renovate bumps | Review by eye |
| 28 | Sync retry with backoff and refresh | Transient webhook or CRD readiness shouldn't fail a wave | No retry |
| 29 | Envoy Gateway is the sole owner of Gateway API CRDs; Cilium Gateway API disabled | Two owners fight over CRD versions | Cilium Gateway API |

## Known gaps

- No backup tool (Velero dropped); no object storage on bare metal.
- No e2e tests yet; version upgrades are checked only by render and API tests.
- EKS paths, Longhorn, and KubeVirt can't be exercised locally.

## Planned

- **E2E on Talos.** Spin up Talos in Docker (`talosctl cluster create`) in CI, run
  bootstrap, core, and platform for the baremetal provider, and assert every Application
  reaches Synced and Healthy. Run it nightly, and on pull requests that change e2e-relevant
  paths, such as pins, bootstrap, or the apps/ chart. Its main job is to catch version
  updates that break the stack. Expect Longhorn and KubeVirt to need host support or test
  overrides there; it gets specified once the approach is proven.
- **Rego for in-cluster behavior.** Reuse the conftest policies, or Gatekeeper
  constraints, to assert behavior on a running cluster as part of e2e.
