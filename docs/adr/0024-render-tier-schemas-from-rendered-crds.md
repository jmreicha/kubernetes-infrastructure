---
number: 24
title: "Render-tier schemas from rendered CRDs"
status: accepted
date: 2026-10-11
tags:
  - system
---

# Render-tier schemas from rendered CRDs

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 24), first recorded in commit `d002e84`.

## Considered Options

- Render-tier schemas generated from the rendered CRDs, then the CustomResourceDefinition/catalog at a pinned tag as fallback; the API tier is authoritative
- Catalog only (tracks latest CRDs, not our pins)

## Decision Outcome

Chosen option: Render-tier schemas generated from the rendered CRDs, then the CustomResourceDefinition/catalog at a pinned tag as fallback; the API tier is authoritative.

Exact match to our pins; the catalog covers CRDs that operators create at runtime.
