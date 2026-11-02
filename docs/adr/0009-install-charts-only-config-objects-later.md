---
number: 9
title: "Install charts only, config objects later"
status: accepted
date: 2026-10-11
tags:
  - system
---

# Install charts only, config objects later

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 9), first recorded in commit `5b0b4c6`.

## Considered Options

- Charts only; config objects are a follow-up
- Charts + day-1 config

## Decision Outcome

Chosen option: Charts only; config objects are a follow-up.

Smallest working foundation; config needs per-cluster input.
