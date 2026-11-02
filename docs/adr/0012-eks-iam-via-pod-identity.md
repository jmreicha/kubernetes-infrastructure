---
number: 12
title: "EKS IAM via Pod Identity"
status: accepted
date: 2026-10-11
tags:
  - security
---

# EKS IAM via Pod Identity

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 12), first recorded in commit `5b0b4c6`.

## Considered Options

- EKS IAM via Pod Identity, created outside the cluster
- IRSA annotations

## Decision Outcome

Chosen option: EKS IAM via Pod Identity, created outside the cluster.

No role ARNs in chart values.
