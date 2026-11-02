---
number: 13
title: "Crossplane for cloud resources"
status: accepted
date: 2026-10-11
tags:
  - system
---

# Crossplane for cloud resources

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 13), first recorded in commit `5b0b4c6`.

## Considered Options

- Crossplane, not ACK or kro
- ACK + kro
- both with split ownership

## Decision Outcome

Chosen option: Crossplane, not ACK or kro.

One control plane on both providers.
