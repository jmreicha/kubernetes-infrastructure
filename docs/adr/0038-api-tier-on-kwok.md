---
number: 38
title: "API tier on kwok"
status: accepted
date: 2026-10-11
tags:
  - system
---

# API tier on kwok

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 38), first recorded in commit `c3d5e69`.

## Considered Options

- API tier on kwok, creating destination and rendered namespaces first
- envtest
- kind

## Decision Outcome

Chosen option: API tier on kwok, creating destination and rendered namespaces first.

A real kube-apiserver without nodes, in seconds; mirrors Argo CD ordering.
