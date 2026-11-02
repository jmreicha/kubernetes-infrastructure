---
number: 42
title: "Pod Security baseline with restricted warnings"
status: accepted
date: 2026-10-11
tags:
  - security
---

# Pod Security baseline with restricted warnings

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 42), first recorded in commit `c3d5e69`.

## Considered Options

- Pod Security: managed namespaces enforce baseline (privileged only where host access is needed), warn/audit restricted
- Restricted everywhere (most charts fail it)

## Decision Outcome

Chosen option: Pod Security: managed namespaces enforce baseline (privileged only where host access is needed), warn/audit restricted.

Host access is explicit and reviewable; restricted gaps show up as warnings.
