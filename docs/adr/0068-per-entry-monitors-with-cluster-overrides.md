---
number: 68
title: Per-entry monitors with cluster overrides
status: accepted
date: 2026-11-02
tags:
  - observability
links:
  - target: 65
    kind: amends
---

# Per-entry monitors with cluster overrides

## Context and Problem Statement

With a metrics stack enabled (ADR 65), most catalog charts can render their own ServiceMonitor or
PodMonitor, each behind a differently named value. Core infrastructure should be scraped by
default; most platform components and add-ons don't need to be, but should be easy to turn on.

## Considered Options

- A `monitor` values snippet per catalog entry, a default-on set, and `monitor.add`/`monitor.remove` in cluster values
- A templated `serviceMonitor.enabled` line in every entry's values
- Hand-written ServiceMonitors in the cluster/ chart

## Decision Outcome

Chosen option: entries carry a `monitor` snippet (the chart-specific values) and optionally
`monitorByDefault`; the cluster/ chart merges the snippet over the entry's values when a stack is
enabled and the entry is monitored. Cluster values add or remove entries by name, like
`enable`/`disable` (ADR 53).

The condition lives in one template, so entries stay plain values. Because an entry that isn't
installed is never rendered, its monitor can't appear on its own. The render tier fails any
monitored Application whose chart renders no monitor, so a chart that renames its key on upgrade
fails CI instead of silently losing its monitor.

The prometheus-operator CRDs move to the bootstrap layer (wave 0): Cilium and Argo CD are
monitored by default and sync in wave 0, so CRDs in core would never arrive. Bootstrap and the
Talos patch install Cilium and Argo CD without their monitors; Argo CD adds them on adoption.

### Consequences

- Good, because turning a monitor on is a one-word change in cluster values.
- Good, because CI derives what to check from the catalog; there is no separate list.
- Bad, because each snippet is chart-specific and needs updating when a chart restructures; the
  render tier monitors every snippet in each fixture with a stack, so CI catches it for any entry
  installed in such a fixture (rook-ceph-cluster isn't yet).
- Bad, because envoy-gateway, crossplane, and gatekeeper have no chart switch and aren't monitored.
- Bad, because the render tier assumes the monitoring API exists whenever a fixture enables a
  stack, which matches Argo CD only once the CRDs are installed.
