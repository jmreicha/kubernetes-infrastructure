---
number: 3
title: "Three layers (bootstrap, core, platform)"
status: accepted
date: 2026-10-11
tags:
  - system
---

# Three layers (bootstrap, core, platform)

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 3), first recorded in commit `5b0b4c6`.

## Considered Options

- Three layers: bootstrap, core, platform
- Flat list

## Decision Outcome

Chosen option: Three layers: bootstrap, core, platform.

Core can come up alone; platform relies on core's guarantees.
