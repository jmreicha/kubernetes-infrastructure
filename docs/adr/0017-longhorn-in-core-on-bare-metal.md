---
number: 17
title: "Longhorn in core on bare metal"
status: accepted
date: 2026-10-11
tags:
  - storage
---

# Longhorn in core on bare metal

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 17), first recorded in commit `d002e84`.

## Considered Options

- Longhorn in core on bare metal, optional
- Platform layer

## Decision Outcome

Chosen option: Longhorn in core on bare metal, optional.

Default StorageClass there; peer of EBS CSI.
