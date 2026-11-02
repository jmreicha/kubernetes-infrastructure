---
number: 62
title: "Opt-in identity add-ons with external Postgres"
status: accepted
date: 2026-10-15
tags:
  - security
---

# Opt-in identity add-ons with external Postgres

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 62), first recorded in commit `ca600f9`.

## Considered Options

- Authentik, Keycloak, and oauth2-proxy as opt-in platform add-ons; external Postgres; no routes
- Bundled Bitnami Postgres
- OpenEverest-provisioned databases
- routes under `domain`

## Decision Outcome

Chosen option: Authentik, Keycloak, and oauth2-proxy as opt-in platform add-ons; external Postgres; no routes.

Pick an IdP per cluster; databases stay with whatever runs them (RDS, DO Managed DB, OpenEverest).
