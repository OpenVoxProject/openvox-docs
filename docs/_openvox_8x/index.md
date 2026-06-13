---
layout: default
title: "OpenVox 8"
---

OpenVox is a community-maintained implementation of Puppet — a configuration management system for Linux, Unix, and Windows. It manages system state through a declarative language, compiling node-specific catalogs and enforcing them on each managed host.

When Perforce discontinued public distribution of Puppet Open Source in late 2024, Overlook InfraTech stepped in with community packaging, and the project was subsequently adopted under [Vox Pupuli](https://voxpupuli.org/) stewardship as OpenVox. A Puppet Standards Steering Committee guides language and feature evolution going forward.

OpenVox is downstream-compatible with Puppet Open Source — existing manifests, modules, Hiera data, and tooling work unchanged.

## How it works

OpenVox operates in two modes:

**Agent/server** — Managed nodes run `openvox-agent` as a background service. Periodically, each agent sends facts (system inventory data) to an [OpenVox Server](/openvox-server/latest/), receives a compiled catalog, and enforces it. Results are reported back to the server. Communication is HTTPS with mutual TLS.

**Standalone** — The `puppet apply` command compiles and applies a catalog locally, with no server required.

## Core packages

| Package | Contents |
|---|---|
| `openvox-agent` | OpenVox, OpenFact, Hiera, bundled Ruby and OpenSSL |
| `openvox-server` | JVM-based catalog server; depends on `openvox-agent` |

See [Component versions in recent OpenVox releases](component_versions.html) for exact version tables.

## Getting started

1. Review [system requirements](system_requirements.html)
2. Work through [pre-install tasks](install_pre.html)
3. Install on [Linux](install_linux.html), [Windows](install_windows.html), or [macOS](install_osx.html)

For community help and a list of commercial support partners, see the [support page](https://voxpupuli.org/openvox/support/).
