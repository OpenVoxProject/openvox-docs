---
layout: default
title: "Migration orientation"
---

OpenVox is intended to preserve the familiar Puppet language, resource model, module layout, and operational workflows. This page is
a starting point for Puppet users planning a move to OpenVox. Use the linked product docs for detailed procedures.

Migrate server-side services first, then migrate agents. Validate catalog compilation, certificate workflows, environments, Hiera,
and reporting on the server side before rolling agent packages through the fleet.

## What Carries Forward

Most Puppet knowledge remains directly useful when moving to OpenVox:

- Manifests, classes, defined types, resources, and modules use the same language model.
- Hiera remains the data lookup system for separating configuration data from code.
- Agents and servers continue to use certificates for authenticated communication.
- PuppetDB-compatible reporting and query workflows are represented by OpenVoxDB.
- Existing Puppet Forge modules are generally usable because the module structure and language remain compatible.

Start with the [OpenVox overview](/openvox/latest/) and the [project map](./projects.html) to orient yourself before changing
packages or services.

## Before You Change Packages

Review the current layout and configuration on the systems you plan to migrate.

- Back up server-side state before changing packages. At minimum, preserve the CA, OpenVox Server configuration, OpenVoxDB/PostgreSQL
  data if used, and your control repo or deployed code.
- Confirm installed components and expected paths with [what gets installed](/openvox/latest/install_what_and_where.html).
- Review important settings in [configuration settings](/openvox/latest/config_about_settings.html) and
  [important configuration settings](/openvox/latest/config_important_settings.html).
- Check `puppet.conf` behavior with the [main configuration file reference](/openvox/latest/config_file_main.html).
- Review existing module and environment workflows with [module fundamentals](/openvox/latest/modules_fundamentals.html) and
  [environments](/openvox/latest/environments_about.html).
- Review Hiera usage with the [Hiera introduction](/openvox/latest/hiera_intro.html) and
  [Hiera configuration](/openvox/latest/hiera_config_yaml_5.html).

## Agents

For agent systems, focus on package replacement, service behavior, and certificate state.

- Install agents with the [Linux installation guide](/openvox/latest/install_linux.html).
- Review [agent services on Unix](/openvox/latest/services_agent_unix.html) or
  [agent services on Windows](/openvox/latest/services_agent_windows.html).
- Review certificate behavior with the [certificate API overview](/openvox-server/latest/http_certificate.html), especially if you
  need to clean or reissue certificates during testing.

## Primary Servers

For primary servers, plan the server-side changes separately from agent rollout.

- Start with the [OpenVox Server overview](/openvox-server/latest/).
- Review [OpenVox Server configuration](/openvox-server/latest/configuration.html).
- Review [server service management](/openvox-server/latest/services_puppetserver.html).
- Review [certificate request](/openvox-server/latest/http_certificate_request.html),
  [certificate status](/openvox-server/latest/http_certificate_status.html), and
  [certificate cleanup](/openvox-server/latest/http_certificate_clean.html) workflows.
- Check [OpenVox Server known issues](/openvox-server/latest/known_issues.html) before rollout.

## Reporting and Queries

If your Puppet deployment uses PuppetDB-compatible workflows, review OpenVoxDB separately.

- Start with the [OpenVoxDB overview](/openvoxdb/latest/).
- Install from packages with the [OpenVoxDB package guide](/openvoxdb/latest/install_from_packages.html).
- Configure OpenVoxDB with the [configuration guide](/openvoxdb/latest/configure.html).
- Connect it to the server with [connecting OpenVox Server](/openvoxdb/latest/connect_puppet_server.html).
- Review upgrade considerations in the [OpenVoxDB upgrade guide](/openvoxdb/latest/upgrade.html).
- For multi-node OpenVoxDB deployments, review
  [database migration coordination](/openvoxdb/latest/migration_coordination.html).

## Suggested Rollout Shape

Use the same release discipline you would use for infrastructure code changes:

1. Inventory agents, primary servers, OpenVoxDB/PuppetDB nodes, and integrations.
2. Confirm package repositories and versions for each platform.
3. Back up server-side state, especially the CA and OpenVoxDB/PostgreSQL data if OpenVoxDB is in use.
4. Migrate and validate server-side services first, including OpenVox Server and OpenVoxDB if it is in use.
5. Test server-side workflows, including certificates, catalog compilation, environments, Hiera, reports, and queries.
6. Test an agent against the migrated server-side services in a non-production environment.
7. Roll agent package changes out in batches, keeping existing environment and Hiera workflows stable.

This page is intentionally not a replacement for an environment-specific migration runbook. Treat it as a map to the docs you need
while writing that runbook.
