---
number: 67
title: Opt-in GitHub Actions runners with ARC
status: accepted
date: 2026-11-02
tags:
  - system
---

# Opt-in GitHub Actions runners with ARC

## Context and Problem Statement

Clusters should be able to run GitHub Actions jobs on their own nodes. Actions Runner Controller
(ARC) ships two official charts: the controller, and a runner scale set that is useless without a
GitHub URL and credentials, which ADR 9 would normally defer as per-cluster config.

## Considered Options

- Controller plus one scale set, enabled together with `enable: [arc]`
- Controller only, scale sets managed outside this repo
- The legacy summerwind controller

## Decision Outcome

Chosen option: opt-in `arc` (controller in `arc-systems`, platform wave 3) that brings one
`arc-runners` scale set (wave 4), named after the cluster and registered at `arc.githubConfigUrl`,
authenticating as a GitHub App seeded from 1Password, in Kubernetes container mode, scaling
from zero to `arc.maxRunners` (default 5).

This is a deliberate exception to ADR 9: a controller with no scale set gives a cluster nothing,
and the scale set needs only one URL and one Secret. The summerwind controller is deprecated.

### Consequences

- Good, because workflows target a cluster with `runs-on: <clusterName>` once it is enabled.
- Good, because a GitHub App scopes permissions to its installation and isn't tied to a person.
- Good, because Kubernetes mode runs job containers as pods without privileged runners, so
  `arc-runners` stays a baseline namespace. Jobs without `container:` run in the runner pod.
- Bad, because workflows that need a Docker daemon (`docker build`, Docker-based actions) don't
  work; that needs dind mode and a privileged namespace.
- Bad, because the scale set chart can't discover the controller with Helm `lookup` under Argo CD,
  so its service account is set explicitly and must track the controller's release name.
- Bad, because the runner image is pinned here and bumped by Renovate, separately from the chart.
