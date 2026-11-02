---
number: 63
title: "Opt-in NFS and iSCSI storage on bare metal"
status: accepted
date: 2026-10-15
tags:
  - storage
---

# Opt-in NFS and iSCSI storage on bare metal

## Context and Problem Statement

Backfilled from the former Decisions table in [design.md](../design.md) (row 63), first recorded in commit `5b664c3`.

## Considered Options

- NFS via csi-driver-nfs and iSCSI via democratic-csi, opt-in on bare metal, non-default classes
- kubernetes-csi/csi-driver-iscsi (no chart, last release 2022, static PVs only)
- making either the default class

## Decision Outcome

Chosen option: NFS via csi-driver-nfs and iSCSI via democratic-csi, opt-in on bare metal, non-default classes.

Use existing NAS storage next to the default class; democratic-csi provisions iSCSI dynamically and is maintained.
