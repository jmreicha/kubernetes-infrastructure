---
number: 44
title: "Cilium WireGuard encryption"
status: accepted
date: 2026-10-11
tags:
  - networking
  - security
---

# Cilium WireGuard encryption

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 44), first recorded in commit `c3d5e69`.

## Considered Options

- Cilium WireGuard encryption
- IPsec
- none

## Decision Outcome

Chosen option: Cilium WireGuard encryption.

Pod traffic encrypted between nodes with one flag.
