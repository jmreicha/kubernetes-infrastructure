---
number: 5
title: "Helm app-of-apps with one values file per cluster"
status: accepted
date: 2026-10-11
tags:
  - system
---

# Helm app-of-apps with one values file per cluster

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 5), first recorded in commit `5b0b4c6`.

## Considered Options

- Helm app-of-apps with `clusters/<name>.yaml`
- Kustomize overlays
- ApplicationSet + cluster secret

## Decision Outcome

Chosen option: Helm app-of-apps with `clusters/<name>.yaml`.

Familiar; one values file per cluster.
