---
number: 28
title: "Sync retry with backoff"
status: accepted
date: 2026-10-11
tags:
  - system
---

# Sync retry with backoff

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 28), first recorded in commit `d002e84`.

## Considered Options

- Sync retry with backoff and refresh
- No retry

## Decision Outcome

Chosen option: Sync retry with backoff and refresh.

Transient webhook or CRD readiness shouldn't fail a wave.
