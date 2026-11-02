---
number: 49
title: "Pin tools with mise"
status: accepted
date: 2026-10-11
tags:
  - system
---

# Pin tools with mise

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 49), first recorded in commit `c3d5e69`.

## Considered Options

- Tools pinned in mise.toml; CI uses mise-action
- curl installs
- per-tool actions

## Decision Outcome

Chosen option: Tools pinned in mise.toml; CI uses mise-action.

Same versions locally and in CI.
