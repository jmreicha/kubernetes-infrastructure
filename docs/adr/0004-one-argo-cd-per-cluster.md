---
number: 4
title: "One Argo CD per cluster"
status: accepted
date: 2026-10-11
tags:
  - system
---

# One Argo CD per cluster

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 4), first recorded in commit `5b0b4c6`.

## Considered Options

- One Argo CD per cluster
- Hub Argo with ApplicationSets

## Decision Outcome

Chosen option: One Argo CD per cluster.

Simplest, no cross-cluster credentials, small blast radius.
