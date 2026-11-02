---
number: 30
title: "local-path-provisioner when Longhorn is off"
status: accepted
date: 2026-10-11
tags:
  - storage
---

# local-path-provisioner when Longhorn is off

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 30), first recorded in commit `d002e84`.

## Considered Options

- Without Longhorn: local-path-provisioner, or bring your own StorageClass
- Dropping the storage guarantee

## Decision Outcome

Chosen option: Without Longhorn: local-path-provisioner, or bring your own StorageClass.

Lighter clusters keep a default StorageClass; platform's input is unchanged.
