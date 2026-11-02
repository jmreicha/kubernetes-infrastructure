---
number: 69
title: Opt-in OpenBao, auto-unsealed and self-initialized
status: accepted
date: 2026-11-02
tags:
  - security
---

# Opt-in OpenBao, auto-unsealed and self-initialized

## Context and Problem Statement

Clusters may want an in-cluster secrets manager for dynamic secrets and secrets apps write back.
A fresh OpenBao install is sealed and uninitialized, and both steps are normally manual: someone
holds unseal keys and a root token, which doesn't fit GitOps or a cluster that restarts unattended.

## Considered Options

- Static seal key from 1Password, self-initialization, HA Raft (3 replicas), apps through external-secrets
- Manual Shamir unseal and `bao operator init`
- Cloud KMS auto-unseal (AWS KMS on EKS only)
- Standalone single replica
- Agent injector or CSI provider for app access

## Decision Outcome

Chosen option: opt-in `openbao` in the platform layer (wave 3, it needs the default StorageClass),
three Raft replicas joined by `retry_join`, auto-unsealed by a static seal key that bootstrap
seeds from 1Password, and self-initialized with only the Kubernetes auth method and an `admin`
role bound to the `openbao-admin` ServiceAccount. No injector, CSI provider, or route; apps read
OpenBao through external-secrets, whose namespace is allowed in.

OpenBao recommends the static seal when another secrets manager is already the root of trust,
which 1Password is here, and it behaves the same on every provider. Self-initialization needs an
auto-unseal and never returns a root token, so nothing privileged leaves the cluster. Its two
requests are config, a deliberate exception to ADR 9: without an auth method nobody can log in.

### Consequences

- Good, because pods unseal themselves after restarts and node loss, on every provider.
- Good, because admin access is a token from `kubectl -n openbao create token openbao-admin`,
  used to log in to the Kubernetes auth method as role `admin`; there are no recovery keys to store.
- Bad, because anyone who can read the `openbao-seal` Secret or the 1Password item can decrypt
  OpenBao's storage; protect both like the data itself.
- Bad, because rotating the seal key means setting `previous_key` alongside a new current key.
- Bad, because the listener is plain HTTP inside the cluster, relying on Cilium's WireGuard
  encryption (ADR 44), which doks doesn't have; TLS from cert-manager is a follow-up.
- Bad, because there's no monitor snippet yet; metrics need a telemetry stanza in the HCL config.
