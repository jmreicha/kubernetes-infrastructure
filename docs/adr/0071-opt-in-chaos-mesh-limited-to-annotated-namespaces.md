---
number: 71
title: Opt-in Chaos Mesh limited to annotated namespaces
status: accepted
date: 2026-11-09
tags:
  - observability
---

# Opt-in Chaos Mesh limited to annotated namespaces

## Context and Problem Statement

Teams want to test how workloads behave under pod, network, I/O, stress, time, and DNS faults.
Chaos Mesh does this with CRDs, but its daemon runs privileged with hostPID on every node, and an
experiment aimed at the wrong namespace can take down core components.

## Considered Options

- Opt-in Chaos Mesh, experiments only in annotated namespaces, dashboard and DNS chaos server on
- Optional (installed by default) like the other platform tools
- Experiments allowed in any namespace (the chart default)
- Leaving out the dashboard or the DNS chaos server

## Decision Outcome

Chosen option: opt-in `chaos-mesh` in the platform layer (wave 3), namespace `chaos-mesh`, with
`enableFilterNamespace` so an experiment only affects namespaces annotated
`chaos-mesh.org/inject=enabled`. The daemon talks to containerd at
`/run/containerd/containerd.sock`, which EKS (AL2023), Talos, and DOKS share. Certificates come
from cert-manager (ADR 36), and chaosd's client certificate is off, since no physical machines are
targeted. The dashboard runs in token security mode with no route, and the DNS chaos server is on.

Fault injection isn't something every cluster wants, and the privileged daemon is a large
footprint, so it's opt-in. The namespace filter keeps bootstrap and core out of reach unless
someone annotates them on purpose.

### Consequences

- Good, because an experiment can't touch a namespace nobody annotated.
- Good, because the dashboard needs a ServiceAccount token, so access follows Kubernetes RBAC.
- Bad, because `chaos-mesh` is a privileged namespace: the daemon needs hostPID, privileged
  containers, and host paths.
- Bad, because the chart puts a random `rollme` annotation on the controller and daemon pods on
  every render; it is ignored in Argo CD, so pods don't restart on each sync, but a real
  certificate rotation won't restart them either.
- Bad, because `chaos-mesh` allows DNS from the whole cluster, so DNSChaos targets can reach it.
- Bad, because a node with another runtime or socket path (Bottlerocket, for example) needs a
  different `chaosDaemon.socketPath`.
