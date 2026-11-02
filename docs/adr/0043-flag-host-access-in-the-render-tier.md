---
number: 43
title: "Flag host access in the render tier"
status: accepted
date: 2026-10-11
tags:
  - security
---

# Flag host access in the render tier

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 43), first recorded in commit `c3d5e69`.

## Considered Options

- Render-tier Rego flags host access in baseline namespaces
- Rely on admission warnings

## Decision Outcome

Chosen option: Render-tier Rego flags host access in baseline namespaces.

Catches it before Argo CD does, with the workload named.
