---
number: 16
title: "Talos for bare metal"
status: accepted
date: 2026-10-11
tags:
  - compute
---

# Talos for bare metal

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 16), first recorded in commit `5b0b4c6`.

## Considered Options

- Talos for bare metal
- k3s, RKE2, kubeadm

## Decision Outcome

Chosen option: Talos for bare metal.

Immutable; handles reboots and upgrades itself, so no kured.
