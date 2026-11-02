---
number: 26
title: "Render with Argo CD's bundled Helm and Kustomize"
status: accepted
date: 2026-10-11
tags:
  - system
---

# Render with Argo CD's bundled Helm and Kustomize

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 26), first recorded in commit `d002e84`.

## Considered Options

- CI renders with the Helm and Kustomize versions bundled in the pinned Argo CD
- Latest tools

## Decision Outcome

Chosen option: CI renders with the Helm and Kustomize versions bundled in the pinned Argo CD.

A render that passes only with other versions proves nothing.
