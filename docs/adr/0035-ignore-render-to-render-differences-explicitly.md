---
number: 35
title: "Ignore render-to-render differences explicitly"
status: accepted
date: 2026-10-11
tags:
  - system
---

# Ignore render-to-render differences explicitly

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 35), first recorded in commit `c3d5e69`.

## Considered Options

- Render each chart twice; anything that differs needs `ignoreDifferences` + `RespectIgnoreDifferences`
- Policing every Secret with data (flags deterministic Secrets)

## Decision Outcome

Chosen option: Render each chart twice; anything that differs needs `ignoreDifferences` + `RespectIgnoreDifferences`.

Generated certs, keys, and caBundles otherwise keep Applications OutOfSync and rotate on every sync.
