---
number: 27
title: "PR risk check on rendered trees"
status: accepted
date: 2026-10-11
tags:
  - system
---

# PR risk check on rendered trees

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 27), first recorded in commit `d002e84`.

## Considered Options

- PR risk check compares rendered base and head trees
- Review by eye

## Decision Outcome

Chosen option: PR risk check compares rendered base and head trees.

Catches data-loss and breaking transitions, especially in Renovate bumps.
