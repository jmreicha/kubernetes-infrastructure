---
number: 54
title: "zot as the bare-metal pull-through cache"
status: accepted
date: 2026-10-11
tags:
  - system
---

# zot as the bare-metal pull-through cache

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 54), first recorded in commit `c3d5e69`.

## Considered Options

- zot as the opt-in pull-through cache on bare metal
- Spegel (no cold-pull caching)
- Harbor (heavy)
- registry:2 (one upstream each)

## Decision Outcome

Chosen option: zot as the opt-in pull-through cache on bare metal.

True on-demand cache for several registries in one instance; light; OCI-native.
