---
number: 22
title: "external-dns optional with per-provider DNS"
status: accepted
date: 2026-10-11
tags:
  - networking
---

# external-dns optional with per-provider DNS

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 22), first recorded in commit `5b0b4c6`.

## Considered Options

- external-dns optional (needs `domain`); Route53 on EKS, Cloudflare on bare metal

No alternatives were recorded.

## Decision Outcome

Chosen option: external-dns optional (needs `domain`); Route53 on EKS, Cloudflare on bare metal.

Not every cluster owns a zone.
