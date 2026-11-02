---
number: 41
title: "AppProjects scoped per layer"
status: accepted
date: 2026-10-11
tags:
  - security
---

# AppProjects scoped per layer

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 41), first recorded in commit `c3d5e69`.

## Considered Options

- AppProjects scoped to each layer's catalog repos and namespaces
- `*` sources and destinations

## Decision Outcome

Chosen option: AppProjects scoped to each layer's catalog repos and namespaces.

A layer can't deploy from or into anything it doesn't own.
