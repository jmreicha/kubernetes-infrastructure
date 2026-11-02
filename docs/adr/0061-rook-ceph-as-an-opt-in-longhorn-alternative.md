---
number: 61
title: "Rook Ceph as an opt-in Longhorn alternative"
status: accepted
date: 2026-10-14
tags:
  - storage
---

# Rook Ceph as an opt-in Longhorn alternative

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 61), first recorded in commit `cbd5024`.

## Considered Options

- Rook Ceph as an opt-in alternative to Longhorn on bare metal, block pool only
- Running both
- CephFS and object store by default

## Decision Outcome

Chosen option: Rook Ceph as an opt-in alternative to Longhorn on bare metal, block pool only.

Replicated block storage on raw disks; one default StorageClass, so enabling rook requires disabling longhorn.
