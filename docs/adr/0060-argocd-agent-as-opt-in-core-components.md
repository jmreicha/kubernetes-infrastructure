---
number: 60
title: "argocd-agent as opt-in core components"
status: accepted
date: 2026-10-12
tags:
  - system
---

# argocd-agent as opt-in core components

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 60), first recorded in commit `32c2876`.

## Considered Options

- argocd-agent (agent and principal) as opt-in core components, autonomous mode, mTLS from 1Password
- Hub-managed Argo CD
- agent only

## Decision Outcome

Chosen option: argocd-agent (agent and principal) as opt-in core components, autonomous mode, mTLS from 1Password.

Central visibility while each cluster keeps its own Argo CD; workload clusters dial out, the hub holds no cluster credentials.
