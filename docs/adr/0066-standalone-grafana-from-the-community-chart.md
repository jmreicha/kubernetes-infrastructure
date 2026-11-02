---
number: 66
title: Standalone Grafana from the community chart
status: accepted
date: 2026-11-02
tags:
  - observability
  - security
---

# Standalone Grafana from the community chart

## Context and Problem Statement

Both metrics stacks bundle Grafana, and Grafana's official Helm chart (`grafana/helm-charts`) is
deprecated in favour of the community-maintained `grafana-community/helm-charts`. The bundled
chart also generates a random admin password on every render, which never settles in Argo CD.

## Considered Options

- Standalone `grafana` entry from grafana-community/helm-charts
- grafana-operator
- Grafana bundled with each metrics stack

## Decision Outcome

Chosen option: a standalone opt-in `grafana` entry in `monitoring`, from the community chart,
with its admin password seeded by bootstrap from 1Password and no route.

It is one chart to manage and works with either backend; its default datasource follows whichever
stack is enabled, and a sidecar loads dashboard ConfigMaps from every namespace. grafana-operator
adds an operator and a Grafana custom resource (config, deferred by ADR 9) for multi-instance
features we don't need. Bundling would configure Grafana in two places and tie it to the backend.

### Consequences

- Good, because switching backends only changes the datasource URL.
- Good, because the admin password is a stable seeded Secret, not regenerated per render.
- Bad, because Grafana runs in the privileged `monitoring` namespace, next to node-exporter, so
  it can reach the backend under the default-deny same-namespace rule.
- Bad, because without persistence, UI-made changes are lost on restart; dashboards belong in
  ConfigMaps.
