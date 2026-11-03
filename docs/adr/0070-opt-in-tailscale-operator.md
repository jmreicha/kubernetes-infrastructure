---
number: 70
title: Opt-in Tailscale operator
status: accepted
date: 2026-11-03
tags:
  - networking
---

# Opt-in Tailscale operator

## Context and Problem Statement

Clusters may want to reach workloads, or let workloads reach devices, over a Tailscale tailnet
without public load balancers or DNS. The Tailscale operator does this with Ingress, Service
annotations, and Connector resources, but it needs tailnet credentials and a unique device name.

## Considered Options

- Opt-in operator only, OAuth client from 1Password, API server proxy off
- Workload identity federation instead of a stored OAuth client
- Turning on the API server proxy (auth or noauth mode)
- Also creating a Connector subnet router for the cluster CIDRs

## Decision Outcome

Chosen option: opt-in `tailscale-operator` in the platform layer (wave 3, it installs CRDs),
namespace `tailscale`, authenticated by an OAuth client that bootstrap seeds from 1Password into
`operator-oauth`, registered as `<clusterName>-tailscale-operator` so clusters don't collide on
the tailnet. The API server proxy is off and no Connector is created; apps opt in per Ingress or
Service, and Connectors are per-cluster config.

Workload identity federation needs an OIDC issuer Tailscale can reach, which EKS has but Talos
and DOKS usually don't; a stored client works the same everywhere. The API server proxy and a
subnet router widen what the tailnet can reach, so they stay a deliberate per-cluster choice.

### Consequences

- Good, because exposing a workload privately is one Ingress with `ingressClassName: tailscale`.
- Good, because one 1Password OAuth client can serve every cluster.
- Bad, because the platform AppProject now allows IngressClass, the chart's one cluster-scoped
  kind outside the existing list; an IngressClass only names a controller.
- Bad, because the proxies the operator creates run privileged, so `tailscale` is a privileged
  namespace.
- Bad, because the OAuth client must own the operator's tags (`tag:k8s-operator`, `tag:k8s`) in
  the tailnet policy, which lives outside this repository.
- Bad, because a proxy reaching a workload in a managed namespace is subject to that namespace's
  default-deny policy; allow `tailscale` there per cluster.
