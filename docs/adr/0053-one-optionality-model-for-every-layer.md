---
number: 53
title: One optionality model for every layer
status: accepted
date: 2026-10-11
tags:
  - system
links:
  - target: 21
    kind: amends
---

# One optionality model for every layer

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 53), first recorded in commit `c3d5e69`.

## Considered Options

- One optionality model for every layer: `optional` entries via `disable`, `optIn` entries via `enable`
- Per-feature keys
- disable-only

## Decision Outcome

Chosen option: One optionality model for every layer: `optional` entries via `disable`, `optIn` entries via `enable`.

Same syntax everywhere; the catalog says what may be turned on or off.
