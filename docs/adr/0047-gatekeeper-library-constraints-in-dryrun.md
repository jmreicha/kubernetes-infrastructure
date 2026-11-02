---
number: 47
title: "gatekeeper-library constraints in dryrun"
status: accepted
date: 2026-10-11
tags:
  - security
---

# gatekeeper-library constraints in dryrun

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 47), first recorded in commit `c3d5e69`.

## Considered Options

- gatekeeper-library templates at a pinned commit + 6 baseline Constraints in dryrun
- Enforce now
- Kyverno

## Decision Outcome

Chosen option: gatekeeper-library templates at a pinned commit + 6 baseline Constraints in dryrun.

Audit results before anything blocks; upstream has no releases.
