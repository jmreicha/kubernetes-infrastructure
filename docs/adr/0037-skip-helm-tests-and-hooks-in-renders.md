---
number: 37
title: "Skip Helm tests and hooks in renders"
status: accepted
date: 2026-10-11
tags:
  - system
---

# Skip Helm tests and hooks in renders

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 37), first recorded in commit `c3d5e69`.

## Considered Options

- Render with `--skip-tests`; skip hooks in drift checks

No alternatives were recorded.

## Decision Outcome

Chosen option: Render with `--skip-tests`; skip hooks in drift checks.

Argo CD never runs Helm tests and excludes hooks from sync status.
