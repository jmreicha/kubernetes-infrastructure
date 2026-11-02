---
number: 59
title: No Cilium network policies on DOKS
status: accepted
date: 2026-10-12
tags:
  - networking
  - security
links:
  - target: 45
    kind: amends
---

# No Cilium network policies on DOKS

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 59), first recorded in commit `32c2876`.

## Considered Options

- No CiliumNetworkPolicies on doks for now
- Enforce default-deny on doks

## Decision Outcome

Chosen option: No CiliumNetworkPolicies on doks for now.

DO-managed Cilium can't run audit mode, so they'd enforce untested.
