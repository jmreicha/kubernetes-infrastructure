---
number: 48
title: "Talos may install Cilium"
status: accepted
date: 2026-10-11
tags:
  - networking
  - compute
---

# Talos may install Cilium

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 48), first recorded in commit `c3d5e69`.

## Considered Options

- Talos may install Cilium from a generated inline-manifest patch; bootstrap skips an existing Cilium
- Talos `cni: none` only

## Decision Outcome

Chosen option: Talos may install Cilium from a generated inline-manifest patch; bootstrap skips an existing Cilium.

Talos-installed Cilium is exactly what Argo CD adopts.
