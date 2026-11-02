---
number: 45
title: Default-deny ingress policies in audit mode
status: accepted
date: 2026-10-11
tags:
  - networking
  - security
links:
  - target: 59
    kind: amendedby
---

# Default-deny ingress policies in audit mode

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 45), first recorded in commit `c3d5e69`.

## Considered Options

- Default-deny ingress CiliumNetworkPolicies, in policy audit mode
- Enforce now
- ingress + egress

## Decision Outcome

Chosen option: Default-deny ingress CiliumNetworkPolicies, in policy audit mode.

See what would drop in Hubble before enforcing; egress later.
