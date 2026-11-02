---
number: 52
title: "pluto in the render tier"
status: accepted
date: 2026-10-11
tags:
  - system
---

# pluto in the render tier

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 52), first recorded in commit `c3d5e69`.

## Considered Options

- pluto in the render tier
- kubeconform alone

## Decision Outcome

Chosen option: pluto in the render tier.

Deprecated or removed APIs fail before a Kubernetes upgrade.
