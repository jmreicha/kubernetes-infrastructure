---
number: 50
title: "helm-unittest for chart tests"
status: accepted
date: 2026-10-11
tags:
  - system
---

# helm-unittest for chart tests

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 50), first recorded in commit `c3d5e69`.

## Considered Options

- Chart tests in helm-unittest; bats only for script contracts
- All bats
- Go rewrite

## Decision Outcome

Chosen option: Chart tests in helm-unittest; bats only for script contracts.

Declarative assertions on rendered templates; no shell traps.
