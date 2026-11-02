---
number: 51
title: "oxfmt as the only formatter"
status: accepted
date: 2026-10-11
tags:
  - system
---

# oxfmt as the only formatter

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 51), first recorded in commit `c3d5e69`.

## Considered Options

- oxfmt formats YAML/JSON5/TOML/Markdown; no yamllint
- yamllint + formatter

## Decision Outcome

Chosen option: oxfmt formats YAML/JSON5/TOML/Markdown; no yamllint.

One formatter owns layout; no rule conflicts.
