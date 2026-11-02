---
number: 56
title: "Regression tests for drift and failure paths"
status: accepted
date: 2026-10-11
tags:
  - system
---

# Regression tests for drift and failure paths

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 56), first recorded in commit `c3d5e69`.

## Considered Options

- Tests for spec/code catalog drift, talosctl-validated Talos patches, image pinning, next-version API removals, and the render/risk failure paths
- Trust review

## Decision Outcome

Chosen option: Tests for spec/code catalog drift, talosctl-validated Talos patches, image pinning, next-version API removals, and the render/risk failure paths.

Each caught a real issue when added: a stale spec table, a patch Talos 1.14 rejects, two charts defaulting to `:latest`.
