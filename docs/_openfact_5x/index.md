---
layout: default
title: "OpenFact 5"
---

OpenFact is a cross-platform system profiling library that discovers and reports per-node facts —
structured data about a node's operating system, hardware, networking, and more. Facts are available
in OpenVox manifests as top-scope variables (e.g. `$facts['os']['family']`) and are used by the
catalog compiler to make node-specific decisions.

OpenFact is the community-maintained continuation of Puppet's Facter, originally adopted under
[Vox Pupuli](https://voxpupuli.org/) stewardship alongside OpenVox. It is downstream-compatible
with Facter — existing custom facts and external facts work unchanged.

## How it works

OpenFact runs on each managed node and resolves facts by querying the system directly: reading
`/proc` entries, running shell commands, calling OS APIs, and so on. Results are returned as a
structured hash. When a fact can be resolved in multiple ways (for example, differently on Linux
versus Windows), OpenFact runs the highest-weighted applicable resolution.

**In an agent/server deployment**, OpenFact runs automatically at the start of each agent run.
The collected facts are sent to OpenVox Server and made available to the catalog compiler.
Facts are not persisted without OpenVoxDB — they are used during catalog compilation and then
discarded. The agent run produces a report, which OpenVox Server stores on local disk by default;
without periodic cleanup, report storage will grow unbounded. OpenVoxDB is an optional component
that provides durable storage for facts, catalogs, and reports.

**Standalone**, the `facter` CLI lets you query facts directly on any node — useful for
ad-hoc inspection, debugging, or scripting without triggering a full agent run.

## Included in openvox-agent

OpenFact ships inside the `openvox-agent` package and does not need to be installed separately.
The version bundled with a given agent release is listed in
[Component versions in openvox-agent](/openvox/latest/about_agent.html).

## Getting started

- [Core facts reference](./core_facts.html) — every built-in fact that ships with OpenFact (auto-generated)
- [Custom facts walkthrough](./custom_facts.html) — step-by-step guide to writing and distributing your own facts
- [Custom facts reference](./fact_overview.html) — example-driven quick reference for fact authors
- [Configuring OpenFact](./configuring_openfact.html) — `facter.conf` options
- [CLI reference](./cli.html) — command-line flags and options (auto-generated)
- [Release notes](./release_notes.html) — OpenFact version history
