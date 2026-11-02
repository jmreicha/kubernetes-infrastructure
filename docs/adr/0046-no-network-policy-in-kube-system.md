---
number: 46
title: "No network policy in kube-system"
status: accepted
date: 2026-10-11
tags:
  - networking
  - security
---

# No network policy in kube-system

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 46), first recorded in commit `c3d5e69`.

## Considered Options

- No network policy in kube-system
- Policy with DNS allowances

## Decision Outcome

Chosen option: No network policy in kube-system.

It runs cluster DNS and provider components we don't own.
