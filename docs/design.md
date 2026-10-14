# Cluster Foundation Design

The normative definition lives in the yass specs; start at `root.yass.yaml` or run
`yass list`. This doc holds what the specs can't: the shape at a glance, and why.

## Overview

A fresh cluster plus `clusters/<name>.yaml` goes through three layers, each gated on the
previous one being Synced and Healthy in Argo CD:

| Layer     | Installed by                   | Purpose                                 | Spec             |
| --------- | ------------------------------ | --------------------------------------- | ---------------- |
| bootstrap | `helm install` (once)          | Cilium, Argo CD, seeded secrets         | `spec/bootstrap` |
| core      | Argo CD, AppProject `core`     | Cluster works, is secure and observable | `spec/core`      |
| platform  | Argo CD, AppProject `platform` | What applications consume               | `spec/platform`  |

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

| Kind     | Default       | Cluster values               | Entries                                                                                                                        |
| -------- | ------------- | ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Required | Installed     | Can't be turned off          | Everything not listed below                                                                                                    |
| Optional | Installed     | `disable: [name]` removes it | Every platform component, `longhorn`, `local-path-provisioner`                                                                 |
| Opt-in   | Not installed | `enable: [name]` adds it     | `zot` (bare metal pull-through cache), `rook` (bare metal Ceph), `falco`, `tetragon`, `argocd-agent`, `argocd-agent-principal` |

Naming anything else in either list is rejected. A name the provider doesn't offer, such as
`kubevirt` on EKS, is accepted and does nothing.

- **Storage.** On bare metal, Longhorn is the default. With `disable: [longhorn]`,
  local-path-provisioner becomes the default StorageClass instead (node-local, no
  replication). With both disabled, `defaultStorageClass` names one you provide, and
  bootstrap checks it exists and is the only default. Either way, core still guarantees
  exactly one default StorageClass to the platform layer. `enable: [rook]` runs Rook Ceph
  (block pool only, three-way replicated, over every unused node device) as the default
  instead; it requires `disable: [longhorn]`.
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
and head trees; see `spec/verification`.

## Decisions

| #   | Decision                                                                                                                                                                 | Why                                                                                                                           | Rejected                                                                                                                   |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| 1   | Spec with yass; manifests implemented against it                                                                                                                         | Spec is the reviewable contract; agents implement it repeatably                                                               | Hand-maintained manifests only                                                                                             |
| 2   | Spec requires exact pins; Renovate owns version numbers                                                                                                                  | Spec stays stable; git records what's deployed                                                                                | Versions in spec (weekly churn); per-provider lockfile                                                                     |
| 3   | Three layers: bootstrap, core, platform                                                                                                                                  | Core can come up alone; platform relies on core's guarantees                                                                  | Flat list                                                                                                                  |
| 4   | One Argo CD per cluster                                                                                                                                                  | Simplest, no cross-cluster credentials, small blast radius                                                                    | Hub Argo with ApplicationSets                                                                                              |
| 5   | Helm app-of-apps with `clusters/<name>.yaml`                                                                                                                             | Familiar; one values file per cluster                                                                                         | Kustomize overlays; ApplicationSet + cluster secret                                                                        |
| 6   | Cilium and Argo CD installed imperatively, then adopted by Argo CD                                                                                                       | Pods can't schedule without a CNI                                                                                             | Argo CD installing Cilium                                                                                                  |
| 7   | Cilium replaces the VPC CNI on EKS (ENI mode, no kube-proxy)                                                                                                             | One networking model on both providers                                                                                        | Chaining with VPC CNI                                                                                                      |
| 8   | Cilium LB-IPAM + L2/BGP on bare metal                                                                                                                                    | No extra project                                                                                                              | MetalLB                                                                                                                    |
| 9   | Charts only; config objects are a follow-up                                                                                                                              | Smallest working foundation; config needs per-cluster input                                                                   | Charts + day-1 config                                                                                                      |
| 10  | Exception: KubeVirt and CDI CRs installed                                                                                                                                | Operators deploy nothing without them                                                                                         |                                                                                                                            |
| 11  | Secrets seeded by bootstrap with `op read`; values carry only op:// refs                                                                                                 | Nothing secret in git; one secret source                                                                                      | ESO ClusterSecretStore (counts as config)                                                                                  |
| 12  | EKS IAM via Pod Identity, created outside the cluster                                                                                                                    | No role ARNs in chart values                                                                                                  | IRSA annotations                                                                                                           |
| 13  | Crossplane, not ACK or kro                                                                                                                                               | One control plane on both providers                                                                                           | ACK + kro; both with split ownership                                                                                       |
| 14  | Falco and Tetragon for runtime inspection, both opt-in                                                                                                                   | Not every cluster wants the overhead; Falco has useful rules on day one, Tetragon needs authored TracingPolicies              | Always-on Falco                                                                                                            |
| 15  | Gatekeeper for admission policy, no constraints in v1                                                                                                                    | Requested; constraints are config                                                                                             |                                                                                                                            |
| 16  | Talos for bare metal                                                                                                                                                     | Immutable; handles reboots and upgrades itself, so no kured                                                                   | k3s, RKE2, kubeadm                                                                                                         |
| 17  | Longhorn in core on bare metal, optional                                                                                                                                 | Default StorageClass there; peer of EBS CSI                                                                                   | Platform layer                                                                                                             |
| 18  | KubeVirt and CDI via community charts (naval-group, OCI)                                                                                                                 | Current releases; pass strict validation                                                                                      | encircle360-oss (duplicate YAML keys and null CR fields fail strict validation); Kustomize remote URLs; vendored manifests |
| 19  | Atlas for schema migrations                                                                                                                                              | Versioned and declarative, lints destructive changes                                                                          | SchemaHero                                                                                                                 |
| 20  | Kargo per cluster, promoting within that cluster only                                                                                                                    | Fits Argo-per-cluster without a management cluster                                                                            | Central Kargo control plane                                                                                                |
| 21  | Platform components default on, per-cluster `disable` list                                                                                                               | Clusters stay uniform unless stated                                                                                           | Opt-in list                                                                                                                |
| 22  | external-dns optional (needs `domain`); Route53 on EKS, Cloudflare on bare metal                                                                                         | Not every cluster owns a zone                                                                                                 |                                                                                                                            |
| 23  | Strimzi and OpenEverest on both providers                                                                                                                                | Spec states what's installed, not what apps must use; MSK/RDS stay an app choice                                              | Bare metal only                                                                                                            |
| 24  | Render-tier schemas generated from the rendered CRDs, then the CustomResourceDefinition/catalog at a pinned tag as fallback; the API tier is authoritative               | Exact match to our pins; the catalog covers CRDs that operators create at runtime                                             | Catalog only (tracks latest CRDs, not our pins)                                                                            |
| 25  | Argo CD Lua health check for child Applications                                                                                                                          | Without it, app-of-apps sync waves don't wait for child health                                                                |                                                                                                                            |
| 26  | CI renders with the Helm and Kustomize versions bundled in the pinned Argo CD                                                                                            | A render that passes only with other versions proves nothing                                                                  | Latest tools                                                                                                               |
| 27  | PR risk check compares rendered base and head trees                                                                                                                      | Catches data-loss and breaking transitions, especially in Renovate bumps                                                      | Review by eye                                                                                                              |
| 28  | Sync retry with backoff and refresh                                                                                                                                      | Transient webhook or CRD readiness shouldn't fail a wave                                                                      | No retry                                                                                                                   |
| 29  | Envoy Gateway is the sole owner of Gateway API CRDs; Cilium Gateway API disabled                                                                                         | Two owners fight over CRD versions                                                                                            | Cilium Gateway API                                                                                                         |
| 30  | Without Longhorn: local-path-provisioner, or bring your own StorageClass                                                                                                 | Lighter clusters keep a default StorageClass; platform's input is unchanged                                                   | Dropping the storage guarantee                                                                                             |
| 31  | local-path-provisioner from upstream git at a release tag                                                                                                                | No official Helm repo; community repackagings lag                                                                             | containeroo and other community charts                                                                                     |
| 32  | kubechecks in platform, needs `domain`, tokens seeded by bootstrap                                                                                                       | Needs GitHub and Argo CD tokens; a bad token shouldn't block core                                                             | Core; drop from v1                                                                                                         |
| 33  | OpenEverest with its bundled OLM, telemetry off, its kube-state-metrics off                                                                                              | OLM is how Everest manages DB operators; core runs KSM                                                                        | Raw Percona/CNPG operators                                                                                                 |
| 34  | external-dns `policy: sync`                                                                                                                                              | Records never go stale                                                                                                        | `upsert-only` (never deletes)                                                                                              |
| 35  | Render each chart twice; anything that differs needs `ignoreDifferences` + `RespectIgnoreDifferences`                                                                    | Generated certs, keys, and caBundles otherwise keep Applications OutOfSync and rotate on every sync                           | Policing every Secret with data (flags deterministic Secrets)                                                              |
| 36  | Prefer chart cert modes that don't generate per render (Hubble CronJob, AWS LB controller via cert-manager)                                                              | Nothing to ignore, nothing rotates                                                                                            | `ignoreDifferences` everywhere                                                                                             |
| 37  | Render with `--skip-tests`; skip hooks in drift checks                                                                                                                   | Argo CD never runs Helm tests and excludes hooks from sync status                                                             |                                                                                                                            |
| 38  | API tier on kwok, creating destination and rendered namespaces first                                                                                                     | A real kube-apiserver without nodes, in seconds; mirrors Argo CD ordering                                                     | envtest; kind                                                                                                              |
| 39  | scripts/bootstrap-cluster waits for the core and platform roots (30m each) and names failing Applications                                                                | Something has to report the outcome; Argo CD has no timeouts                                                                  | Leave it to the Argo CD UI                                                                                                 |
| 40  | metrics-server `--kubelet-insecure-tls` on bare metal                                                                                                                    | Talos kubelets serve self-signed certs by default                                                                             | Kubelet cert rotation + serving-cert approver                                                                              |
| 41  | AppProjects scoped to each layer's catalog repos and namespaces                                                                                                          | A layer can't deploy from or into anything it doesn't own                                                                     | `*` sources and destinations                                                                                               |
| 42  | Pod Security: managed namespaces enforce baseline (privileged only where host access is needed), warn/audit restricted                                                   | Host access is explicit and reviewable; restricted gaps show up as warnings                                                   | Restricted everywhere (most charts fail it)                                                                                |
| 43  | Render-tier Rego flags host access in baseline namespaces                                                                                                                | Catches it before Argo CD does, with the workload named                                                                       | Rely on admission warnings                                                                                                 |
| 44  | Cilium WireGuard encryption                                                                                                                                              | Pod traffic encrypted between nodes with one flag                                                                             | IPsec; none                                                                                                                |
| 45  | Default-deny ingress CiliumNetworkPolicies, in policy audit mode                                                                                                         | See what would drop in Hubble before enforcing; egress later                                                                  | Enforce now; ingress + egress                                                                                              |
| 46  | No network policy in kube-system                                                                                                                                         | It runs cluster DNS and provider components we don't own                                                                      | Policy with DNS allowances                                                                                                 |
| 47  | gatekeeper-library templates at a pinned commit + 6 baseline Constraints in dryrun                                                                                       | Audit results before anything blocks; upstream has no releases                                                                | Enforce now; Kyverno                                                                                                       |
| 48  | Talos may install Cilium from a generated inline-manifest patch; bootstrap skips an existing Cilium                                                                      | Talos-installed Cilium is exactly what Argo CD adopts                                                                         | Talos `cni: none` only                                                                                                     |
| 49  | Tools pinned in mise.toml; CI uses mise-action                                                                                                                           | Same versions locally and in CI                                                                                               | curl installs; per-tool actions                                                                                            |
| 50  | Chart tests in helm-unittest; bats only for script contracts                                                                                                             | Declarative assertions on rendered templates; no shell traps                                                                  | All bats; Go rewrite                                                                                                       |
| 51  | oxfmt formats YAML/JSON5/TOML/Markdown; no yamllint                                                                                                                      | One formatter owns layout; no rule conflicts                                                                                  | yamllint + formatter                                                                                                       |
| 52  | pluto in the render tier                                                                                                                                                 | Deprecated or removed APIs fail before a Kubernetes upgrade                                                                   | kubeconform alone                                                                                                          |
| 53  | One optionality model for every layer: `optional` entries via `disable`, `optIn` entries via `enable`                                                                    | Same syntax everywhere; the catalog says what may be turned on or off                                                         | Per-feature keys; disable-only                                                                                             |
| 54  | zot as the opt-in pull-through cache on bare metal                                                                                                                       | True on-demand cache for several registries in one instance; light; OCI-native                                                | Spegel (no cold-pull caching); Harbor (heavy); registry:2 (one upstream each)                                              |
| 55  | ECR pull-through cache on EKS, outside the cluster                                                                                                                       | AWS-managed; no in-cluster storage or node mirror plumbing                                                                    | zot on EKS                                                                                                                 |
| 56  | Tests for spec/code catalog drift, talosctl-validated Talos patches, image pinning, next-version API removals, and the render/risk failure paths                         | Each caught a real issue when added: a stale spec table, a patch Talos 1.14 rejects, two charts defaulting to `:latest`       | Trust review                                                                                                               |
| 57  | `doks` as a third provider, relying on what DigitalOcean manages: Cilium, CoreDNS, Block Storage CSI (`do-block-storage`), load balancers, node autoscaling, Gateway API | Don't install or fight managed components; DO reconciles objects labelled `doks.digitalocean.com/managed`                     | Replace DO's Cilium; Envoy Gateway on doks                                                                                 |
| 58  | doks uses DigitalOcean's managed Gateway API, not Envoy Gateway                                                                                                          | DO owns the Gateway API CRDs there; two owners would fight                                                                    | Envoy Gateway without CRDs                                                                                                 |
| 59  | No CiliumNetworkPolicies on doks for now                                                                                                                                 | DO-managed Cilium can't run audit mode, so they'd enforce untested                                                            | Enforce default-deny on doks                                                                                               |
| 60  | argocd-agent (agent and principal) as opt-in core components, autonomous mode, mTLS from 1Password                                                                       | Central visibility while each cluster keeps its own Argo CD; workload clusters dial out, the hub holds no cluster credentials | Hub-managed Argo CD; agent only                                                                                            |
| 61  | Rook Ceph as an opt-in alternative to Longhorn on bare metal, block pool only                                                                                            | Replicated block storage on raw disks; one default StorageClass, so enabling rook requires disabling longhorn                 | Running both; CephFS and object store by default                                                                           |

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
