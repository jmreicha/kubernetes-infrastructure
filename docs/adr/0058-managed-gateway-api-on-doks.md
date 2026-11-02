---
number: 58
title: Managed Gateway API on DOKS
status: accepted
date: 2026-10-12
tags:
  - networking
links:
  - target: 29
    kind: amends
---

# Managed Gateway API on DOKS

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 58), first recorded in commit `32c2876`.

## Considered Options

- doks uses DigitalOcean's managed Gateway API, not Envoy Gateway
- Envoy Gateway without CRDs

## Decision Outcome

Chosen option: doks uses DigitalOcean's managed Gateway API, not Envoy Gateway.

DO owns the Gateway API CRDs there; two owners would fight.
