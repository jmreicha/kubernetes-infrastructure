---
number: 21
title: Platform components on by default with a disable list
status: accepted
date: 2026-10-11
tags:
  - system
links:
  - target: 53
    kind: amendedby
---

# Platform components on by default with a disable list

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 21), first recorded in commit `5b0b4c6`.

## Considered Options

- Platform components default on, per-cluster `disable` list
- Opt-in list

## Decision Outcome

Chosen option: Platform components default on, per-cluster `disable` list.

Clusters stay uniform unless stated.
