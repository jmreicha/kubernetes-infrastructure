---
number: 36
title: "Prefer stable chart certificate modes"
status: accepted
date: 2026-10-11
tags:
  - security
---

# Prefer stable chart certificate modes

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 36), first recorded in commit `c3d5e69`.

## Considered Options

- Prefer chart cert modes that don't generate per render (Hubble CronJob, AWS LB controller via cert-manager)
- `ignoreDifferences` everywhere

## Decision Outcome

Chosen option: Prefer chart cert modes that don't generate per render (Hubble CronJob, AWS LB controller via cert-manager).

Nothing to ignore, nothing rotates.
