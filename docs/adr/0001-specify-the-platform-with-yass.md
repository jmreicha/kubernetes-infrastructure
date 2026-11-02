---
number: 1
title: "Specify the platform with yass"
status: accepted
date: 2026-10-11
tags:
  - system
---

# Specify the platform with yass

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 1), first recorded in commit `5b0b4c6`.

## Considered Options

- Spec with yass; manifests implemented against it
- Hand-maintained manifests only

## Decision Outcome

Chosen option: Spec with yass; manifests implemented against it.

Spec is the reviewable contract; agents implement it repeatably.
