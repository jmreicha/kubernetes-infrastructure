---
number: 39
title: "Bootstrap waits for core and platform"
status: accepted
date: 2026-10-11
tags:
  - system
---

# Bootstrap waits for core and platform

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 39), first recorded in commit `c3d5e69`.

## Considered Options

- scripts/bootstrap-cluster waits for the core and platform roots (30m each) and names failing Applications
- Leave it to the Argo CD UI

## Decision Outcome

Chosen option: scripts/bootstrap-cluster waits for the core and platform roots (30m each) and names failing Applications.

Something has to report the outcome; Argo CD has no timeouts.
