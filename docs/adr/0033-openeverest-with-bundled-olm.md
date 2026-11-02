---
number: 33
title: "OpenEverest with bundled OLM"
status: accepted
date: 2026-10-11
tags:
  - data
---

# OpenEverest with bundled OLM

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 33), first recorded in commit `c3d5e69`.

## Considered Options

- OpenEverest with its bundled OLM, telemetry off, its kube-state-metrics off
- Raw Percona/CNPG operators

## Decision Outcome

Chosen option: OpenEverest with its bundled OLM, telemetry off, its kube-state-metrics off.

OLM is how Everest manages DB operators; core runs KSM.
