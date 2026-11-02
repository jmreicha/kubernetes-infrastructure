---
number: 65
title: Opt-in metrics stacks, Prometheus or VictoriaMetrics
status: accepted
date: 2026-11-02
tags:
  - observability
links:
  - target: 68
    kind: amendedby
---

# Opt-in metrics stacks, Prometheus or VictoriaMetrics

## Context and Problem Statement

Core runs metrics-server, kube-state-metrics, and the OpenTelemetry operator, but nothing stores
metrics or alerts on them. Clusters need a metrics backend they can opt into, and we want a
lighter alternative to Prometheus without two databases scraping the same targets.

## Considered Options

- kube-prometheus-stack and victoria-metrics-k8s-stack as mutually exclusive opt-ins, sharing the prometheus-operator CRDs
- kube-prometheus-stack only
- VictoriaMetrics only
- victoria-metrics-operator alone, without the k8s stack

## Decision Outcome

Chosen option: both stacks as opt-in core entries in `monitoring`, never enabled together
(the values policy rejects it), with `prometheus-operator-crds` installed in wave 1 whenever
either is enabled.

Each stack bundles its operator, so one entry gives a working backend with alerting,
node-exporter, and default rules on day one. The operator-only option would leave us writing and
maintaining VMSingle, VMAgent, and rules ourselves, which ADR 9 defers. The shared CRDs let charts
ship ServiceMonitors either way; the VictoriaMetrics operator converts them.

### Consequences

- Good, because both stacks deliver the same thing, so switching is a values change.
- Good, because the bundled Grafana and kube-state-metrics are off; core's kube-state-metrics gets
  a ServiceMonitor instead, and Grafana is its own entry (ADR 66).
- Good, because webhook certificates come from cert-manager, so nothing rotates per render (ADR 36).
- Bad, because node-exporter needs host access, so `monitoring` is a privileged namespace.
- Bad, because etcd, the controller manager, the scheduler, and kube-proxy aren't scraped; managed
  control planes don't expose them and Cilium replaces kube-proxy.
- Bad, because the VictoriaMetrics dashboard sync job is off (it downloads dashboards at runtime),
  so only kube-prometheus-stack ships dashboards.
- Bad, because storage is the charts' default (no persistent volume) until retention is configured.
