---
number: 14
title: "Falco and Tetragon as opt-in runtime inspection"
status: accepted
date: 2026-10-14
tags:
  - security
---

# Falco and Tetragon as opt-in runtime inspection

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 14), first recorded in commit `cbd5024`.

## Considered Options

- Falco and Tetragon for runtime inspection, both opt-in
- Always-on Falco

## Decision Outcome

Chosen option: Falco and Tetragon for runtime inspection, both opt-in.

Not every cluster wants the overhead; Falco has useful rules on day one, Tetragon needs authored TracingPolicies.
