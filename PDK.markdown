---
layout: default
title: Puppet Development Kit (PDK)
permalink: /pdk.html
---

The **Puppet Development Kit (PDK)** is a package of development and testing tools that helps you create, validate, and test Puppet modules.

> **Note:** Puppet (Perforce) ceased open-source maintenance of PDK at version **3.4.0**. Newer versions are distributed from a protected repository requiring either a Puppet Forge API key or a Puppet Enterprise license ID to download; see [Puppet's PDK documentation](https://help.puppet.com/pdk/current/topics/pdk.htm) for details. Documentation for the last open-source release is available in the [pdk repository on GitHub](https://github.com/puppetlabs/pdk/blob/main/docs/pdk.md).

## Overview

PDK provides a standard set of tools and workflows for developing Puppet modules, including:

- Module scaffolding and structure validation
- Unit testing with rspec-puppet
- Acceptance testing with Litmus
- Metadata validation

## Compatibility with OpenVox

OpenVox is compatible with PDK **3.4.0** and earlier for module development workflows. The last open-source release can be found in the [pdk repository on GitHub](https://github.com/puppetlabs/pdk).

## Open source alternatives

The OpenVox community maintains tooling that replaces PDK workflows without requiring a commercial Puppet account:

- **[VoxBox](https://github.com/voxpupuli/container-voxbox)** — A container image maintained by Vox Pupuli that includes rspec-puppet, Litmus, RuboCop, and other testing gems. It is the recommended way to run unit and acceptance tests for OpenVox modules in CI and local development.
- **[jig](https://github.com/avitacco/jig)** — A Go-based reimplementation of PDK. Ships as a single static binary with no Ruby runtime dependency and supports module scaffolding, building, and releasing.
