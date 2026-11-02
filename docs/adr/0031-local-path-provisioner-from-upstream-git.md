---
number: 31
title: "local-path-provisioner from upstream git"
status: accepted
date: 2026-10-11
tags:
  - storage
---

# local-path-provisioner from upstream git

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 31), first recorded in commit `d002e84`.

## Considered Options

- local-path-provisioner from upstream git at a release tag
- containeroo and other community charts

## Decision Outcome

Chosen option: local-path-provisioner from upstream git at a release tag.

No official Helm repo; community repackagings lag.
