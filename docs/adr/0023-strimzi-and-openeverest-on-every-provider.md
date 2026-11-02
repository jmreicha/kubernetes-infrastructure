---
number: 23
title: "Strimzi and OpenEverest on every provider"
status: accepted
date: 2026-10-11
tags:
  - data
---

# Strimzi and OpenEverest on every provider

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 23), first recorded in commit `5b0b4c6`.

## Considered Options

- Strimzi and OpenEverest on both providers
- Bare metal only

## Decision Outcome

Chosen option: Strimzi and OpenEverest on both providers.

Spec states what's installed, not what apps must use; MSK/RDS stay an app choice.
