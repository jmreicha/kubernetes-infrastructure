---
number: 57
title: "DigitalOcean Kubernetes as a third provider"
status: accepted
date: 2026-10-12
tags:
  - system
---

# DigitalOcean Kubernetes as a third provider

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 57), first recorded in commit `32c2876`.

## Considered Options

- `doks` as a third provider, relying on what DigitalOcean manages: Cilium, CoreDNS, Block Storage CSI (`do-block-storage`), load balancers, node autoscaling, Gateway API
- Replace DO's Cilium
- Envoy Gateway on doks

## Decision Outcome

Chosen option: `doks` as a third provider, relying on what DigitalOcean manages: Cilium, CoreDNS, Block Storage CSI (`do-block-storage`), load balancers, node autoscaling, Gateway API.

Don't install or fight managed components; DO reconciles objects labelled `doks.digitalocean.com/managed`.
