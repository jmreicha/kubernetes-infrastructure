---
number: 11
title: "Seed secrets at bootstrap from 1Password"
status: accepted
date: 2026-10-11
tags:
  - security
---

# Seed secrets at bootstrap from 1Password

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 11), first recorded in commit `5b0b4c6`.

## Considered Options

- Secrets seeded by bootstrap with `op read`; values carry only op:// refs
- ESO ClusterSecretStore (counts as config)

## Decision Outcome

Chosen option: Secrets seeded by bootstrap with `op read`; values carry only op:// refs.

Nothing secret in git; one secret source.
