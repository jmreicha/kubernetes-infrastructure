---
number: 7
title: "Cilium replaces the VPC CNI on EKS"
status: accepted
date: 2026-10-11
tags:
  - networking
---

# Cilium replaces the VPC CNI on EKS

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 7), first recorded in commit `5b0b4c6`.

## Considered Options

- Cilium replaces the VPC CNI on EKS (ENI mode, no kube-proxy)
- Chaining with VPC CNI

## Decision Outcome

Chosen option: Cilium replaces the VPC CNI on EKS (ENI mode, no kube-proxy).

One networking model on both providers.
