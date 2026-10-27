---
layout: default
title: "OpenFact 6"
---

OpenFact is a cross-platform system profiling library that discovers and reports per-node facts —
structured data about a node's operating system, hardware, networking, and more. Facts are available
in OpenVox manifests in the `$facts` hash (for example, `$facts['os']['family']`) and are used by the
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
The agent sends the facts to OpenVox Server, which uses them to compile the node's catalog. The
server also keeps the most recent facts for each node on disk, replacing them on every run.
OpenVoxDB, an optional component, stores facts, catalogs, and reports so you can query them across
nodes.

**Standalone**, the `facter` CLI lets you query facts directly on any node — useful for
ad-hoc inspection, debugging, or scripting without triggering a full agent run.

## Included in openvox-agent

OpenFact ships inside the `openvox-agent` package and does not need to be installed separately.
OpenFact 6 is the series bundled with `openvox-agent` 9.x; the 8.x agent bundles OpenFact 5.
The version bundled with a given agent release is listed in
[Component versions in recent releases](/openvox/9.x/component_versions.html).

OpenFact 6 requires Ruby 3.0 or later (the 9.x agent bundles Ruby 4.0). It drops support for
Ruby 2.5 through 2.7. See the [release notes](./release_notes.html) for the other changes in 6.0.

## Getting started

- [Core facts reference](./core_facts.html) — every built-in fact that ships with OpenFact (auto-generated)
- [Custom facts walkthrough](./custom_facts.html) — step-by-step guide to writing and distributing your own facts
- [Custom facts reference](./fact_overview.html) — example-driven quick reference for fact authors
- [External facts](./external_facts.html) — scripts and structured data files as facts
- [Configuring OpenFact](./configuring_openfact.html) — `facter.conf` options
- [CLI reference](./cli.html) — command-line flags and options (auto-generated)
- [Release notes](./release_notes.html) — OpenFact version history
