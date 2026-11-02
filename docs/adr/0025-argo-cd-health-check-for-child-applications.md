---
number: 25
title: "Argo CD health check for child Applications"
status: accepted
date: 2026-10-11
tags:
  - system
---

# Argo CD health check for child Applications

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 25), first recorded in commit `d002e84`.

## Considered Options

- Argo CD Lua health check for child Applications

No alternatives were recorded.

## Decision Outcome

Chosen option: Argo CD Lua health check for child Applications.

Without it, app-of-apps sync waves don't wait for child health.
