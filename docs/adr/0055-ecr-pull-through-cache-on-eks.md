---
number: 55
title: "ECR pull-through cache on EKS"
status: accepted
date: 2026-10-11
tags:
  - system
---

# ECR pull-through cache on EKS

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 55), first recorded in commit `c3d5e69`.

## Considered Options

- ECR pull-through cache on EKS, outside the cluster
- zot on EKS

## Decision Outcome

Chosen option: ECR pull-through cache on EKS, outside the cluster.

AWS-managed; no in-cluster storage or node mirror plumbing.
