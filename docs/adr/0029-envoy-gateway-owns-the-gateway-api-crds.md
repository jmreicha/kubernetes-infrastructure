---
number: 29
title: Envoy Gateway owns the Gateway API CRDs
status: accepted
date: 2026-10-11
tags:
  - networking
links:
  - target: 58
    kind: amendedby
---

# Envoy Gateway owns the Gateway API CRDs

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 29), first recorded in commit `d002e84`.

## Considered Options

- Envoy Gateway is the sole owner of Gateway API CRDs; Cilium Gateway API disabled
- Cilium Gateway API

## Decision Outcome

Chosen option: Envoy Gateway is the sole owner of Gateway API CRDs; Cilium Gateway API disabled.

Two owners fight over CRD versions.
