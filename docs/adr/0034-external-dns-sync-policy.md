---
number: 34
title: "external-dns sync policy"
status: accepted
date: 2026-10-11
tags:
  - networking
---

# external-dns sync policy

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 34), first recorded in commit `c3d5e69`.

## Considered Options

- external-dns `policy: sync`
- `upsert-only` (never deletes)

## Decision Outcome

Chosen option: external-dns `policy: sync`.

Records never go stale.
