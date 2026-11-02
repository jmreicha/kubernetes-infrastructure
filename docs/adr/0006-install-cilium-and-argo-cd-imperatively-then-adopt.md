---
number: 6
title: "Install Cilium and Argo CD imperatively, then adopt"
status: accepted
date: 2026-10-11
tags:
  - networking
  - system
---

# Install Cilium and Argo CD imperatively, then adopt

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 6), first recorded in commit `5b0b4c6`.

## Considered Options

- Cilium and Argo CD installed imperatively, then adopted by Argo CD
- Argo CD installing Cilium

## Decision Outcome

Chosen option: Cilium and Argo CD installed imperatively, then adopted by Argo CD.

Pods can't schedule without a CNI.
