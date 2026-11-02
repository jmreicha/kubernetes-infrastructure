---
number: 2
title: "Exact version pins owned by Renovate"
status: accepted
date: 2026-10-11
tags:
  - system
---

# Exact version pins owned by Renovate

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 2), first recorded in commit `5b0b4c6`.

## Considered Options

- Spec requires exact pins; Renovate owns version numbers
- Versions in spec (weekly churn)
- per-provider lockfile

## Decision Outcome

Chosen option: Spec requires exact pins; Renovate owns version numbers.

Spec stays stable; git records what's deployed.
