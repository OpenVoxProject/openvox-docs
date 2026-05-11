---
layout: default
title: "Projects"
---

The OpenVox ecosystem is made of focused projects that share the Puppet language, catalog model, and operational conventions.
Use this page to find the canonical documentation for each part of the stack.

## Core Configuration Management

[OpenVox](/openvox/latest/) is the core configuration management project. It includes the Puppet language, resource model, agent,
`puppet` command line interface, catalog application, modules, environments, and Hiera data lookup.

Start with:

- [OpenVox overview](/openvox/latest/)
- [Architecture overview](/openvox/latest/architecture.html)
- [Language summary](/openvox/latest/lang_summary.html)
- [Module fundamentals](/openvox/latest/modules_fundamentals.html)
- [Hiera introduction](/openvox/latest/hiera_intro.html)

## Server-Side Services

[OpenVox Server](/openvox-server/latest/) provides the server-side services used by managed agents. It compiles catalogs, serves
files, manages certificate authority workflows, and exposes server APIs.

Start with:

- [OpenVox Server overview](/openvox-server/latest/)
- [Configuration](/openvox-server/latest/configuration.html)
- [Managing services](/openvox-server/latest/services_puppetserver.html)
- [Restarting OpenVox Server](/openvox-server/latest/restarting.html)

## Data and Querying

[OpenVoxDB](/openvoxdb/latest/) stores catalogs, facts, reports, and resource data. It gives operators a queryable view of managed
infrastructure and backs reporting workflows.

Start with:

- [OpenVoxDB overview](/openvoxdb/latest/)
- [Project overview](/openvoxdb/latest/overview.html)
- [Installing from packages](/openvoxdb/latest/install_from_packages.html)
- [PQL tutorial](/openvoxdb/latest/api/query/tutorial-pql.html)

## Facts

[OpenFact](/openfact/latest/) discovers system facts such as operating system, networking, hardware, and virtualization details.
OpenVox uses facts during catalog compilation and exposes them to manifests through the `$facts` hash.

Start with:

- [OpenFact overview](/openfact/latest/)
- [Fact overview](/openfact/latest/fact_overview.html)
- [Custom facts walkthrough](/openfact/latest/custom_facts.html)
- [Configuring OpenFact](/openfact/latest/configuring_openfact.html)

## Orchestration

[OpenBolt](https://github.com/OpenVoxProject/openbolt) provides agentless orchestration for running commands, scripts, tasks, and
plans. It complements OpenVox by handling directed operational actions that do not need continuous convergence.

Until this documentation site has a local OpenBolt section, use the OpenBolt repository as the canonical project source.

## Modules and Community Projects

OpenVox uses Puppet modules for reusable configuration code. Most existing Puppet Forge modules can be used with OpenVox because the
language and module model remain compatible.

Start with:

- [Module fundamentals](/openvox/latest/modules_fundamentals.html)
- [Roles and profiles](/openvox/latest/the_roles_and_profiles_method.html)
- [Puppet Forge](https://forge.puppet.com/)
- [Vox Pupuli Connect](https://voxpupuli.org/connect/)
