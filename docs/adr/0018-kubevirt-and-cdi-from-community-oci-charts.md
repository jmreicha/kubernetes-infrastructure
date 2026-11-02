---
number: 18
title: "KubeVirt and CDI from community OCI charts"
status: accepted
date: 2026-10-11
tags:
  - compute
---

# KubeVirt and CDI from community OCI charts

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 18), first recorded in commit `c3d5e69`.

## Considered Options

- KubeVirt and CDI via community charts (naval-group, OCI)
- encircle360-oss (duplicate YAML keys and null CR fields fail strict validation)
- Kustomize remote URLs
- vendored manifests

## Decision Outcome

Chosen option: KubeVirt and CDI via community charts (naval-group, OCI).

Current releases; pass strict validation.
