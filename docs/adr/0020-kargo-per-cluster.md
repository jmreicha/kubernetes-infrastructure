---
number: 20
title: "Kargo per cluster"
status: accepted
date: 2026-10-11
tags:
  - system
---

# Kargo per cluster

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 20), first recorded in commit `5b0b4c6`.

## Considered Options

- Kargo per cluster, promoting within that cluster only
- Central Kargo control plane

## Decision Outcome

Chosen option: Kargo per cluster, promoting within that cluster only.

Fits Argo-per-cluster without a management cluster.
