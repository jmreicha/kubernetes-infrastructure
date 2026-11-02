---
number: 64
title: "Record decisions as ADRs with adrs"
status: accepted
date: 2026-11-02
tags:
  - system
---

# Record decisions as ADRs with adrs

## Context and Problem Statement

Decisions lived in a single table in `docs/design.md`. At 63 rows it was hard to review, link,
or supersede one decision without editing the rest.

## Considered Options

- One MADR file per decision in `docs/adr/`, managed by [adrs](https://github.com/joshrotenberg/adrs)
- Keep the Decisions table in `docs/design.md`
- Keep both, with the table as a summary

## Decision Outcome

Chosen option: one MADR file per decision in `docs/adr/`, managed by adrs, in NextGen mode
(YAML frontmatter with tags from the catalog categories).

Each decision can be linked, amended, or superseded on its own, and `adrs doctor` lints them in
pre-commit. The table rows were backfilled as ADRs 1-63 with their original dates; the table was
removed so the two can't drift.
