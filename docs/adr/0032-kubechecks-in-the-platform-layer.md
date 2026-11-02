---
number: 32
title: "kubechecks in the platform layer"
status: accepted
date: 2026-10-11
tags:
  - system
---

# kubechecks in the platform layer

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 32), first recorded in commit `c3d5e69`.

## Considered Options

- kubechecks in platform, needs `domain`, tokens seeded by bootstrap
- Core
- drop from v1

## Decision Outcome

Chosen option: kubechecks in platform, needs `domain`, tokens seeded by bootstrap.

Needs GitHub and Argo CD tokens; a bad token shouldn't block core.
