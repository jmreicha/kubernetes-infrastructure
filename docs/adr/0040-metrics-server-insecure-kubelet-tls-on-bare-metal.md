---
number: 40
title: "metrics-server insecure kubelet TLS on bare metal"
status: accepted
date: 2026-10-11
tags:
  - observability
  - security
---

# metrics-server insecure kubelet TLS on bare metal

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 40), first recorded in commit `c3d5e69`.

## Considered Options

- metrics-server `--kubelet-insecure-tls` on bare metal
- Kubelet cert rotation + serving-cert approver

## Decision Outcome

Chosen option: metrics-server `--kubelet-insecure-tls` on bare metal.

Talos kubelets serve self-signed certs by default.
