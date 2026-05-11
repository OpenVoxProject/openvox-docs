---
layout: default
title: "Learning paths"
---

Use these paths to find the right starting point for your role and current experience. Each path links to the canonical docs for the
topic instead of repeating the material here.

## New to OpenVox

Start with the system model, then move into a small working example.

1. Read the [OpenVox overview](/openvox/latest/).
2. Learn how agents and servers fit together in the [architecture overview](/openvox/latest/architecture.html).
3. Run through the [quick start](/openvox/latest/quick_start.html).
4. Read the [language summary](/openvox/latest/lang_summary.html).
5. Learn how reusable code is organized in [module fundamentals](/openvox/latest/modules_fundamentals.html).
6. Learn how data is separated from code in the [Hiera introduction](/openvox/latest/hiera_intro.html).

## Existing Puppet Users

Focus on the OpenVox project map, compatibility expectations, and operational entry points.

1. Review the [migration orientation](./migration.html) for a high-level picture of what carries forward and how to sequence the move.
2. Review the [project map](./projects.html).
3. Read the [OpenVox overview](/openvox/latest/).
4. Check [installation locations and package contents](/openvox/latest/install_what_and_where.html).
5. Review [important configuration settings](/openvox/latest/config_important_settings.html).
6. Review [OpenVox Server configuration](/openvox-server/latest/configuration.html) if you operate a primary server.
7. Review [OpenVoxDB installation](/openvoxdb/latest/install_from_packages.html) if you use PuppetDB-compatible reporting.

## Module Authors

Start with the module model, then layer on roles, profiles, data, and facts.

1. Read [module fundamentals](/openvox/latest/modules_fundamentals.html).
2. Use the [beginner's guide to modules](/openvox/latest/bgtm.html) for a guided example.
3. Organize site code with the [roles and profiles method](/openvox/latest/the_roles_and_profiles_method.html).
4. Use Hiera with [automatic parameter lookup](/openvox/latest/hiera_automatic.html).
5. Add data hierarchy behavior with [Hiera configuration](/openvox/latest/hiera_config_yaml_5.html).
6. Extend node data with [custom facts](/openfact/latest/custom_facts.html) when built-in facts are not enough.

## Operators

Focus on installation, services, certificates, reports, and query workflows.

1. Install agents with the [Linux installation guide](/openvox/latest/install_linux.html).
2. Review [agent services on Unix](/openvox/latest/services_agent_unix.html) or
   [agent services on Windows](/openvox/latest/services_agent_windows.html).
3. Install and configure server components with [OpenVox Server](/openvox-server/latest/).
4. Review [server service management](/openvox-server/latest/services_puppetserver.html).
5. Understand certificate workflows with the [certificate API docs](/openvox-server/latest/http_certificate.html).
6. Install OpenVoxDB with the [package guide](/openvoxdb/latest/install_from_packages.html).
7. Check service health with [OpenVox Server service docs](/openvox-server/latest/services_puppetserver.html) and
   [OpenVoxDB status docs](/openvoxdb/latest/api/status/v1/status.html).
8. Query infrastructure data with the [PQL tutorial](/openvoxdb/latest/api/query/tutorial-pql.html).

## Contributors

Start with the community entry points, then choose the project whose docs or code you want to improve.

1. Use [Vox Pupuli Connect](https://voxpupuli.org/connect/) for current communication channels.
2. Browse the [OpenVox GitHub organization](https://github.com/OpenVoxProject).
3. Use the [project map](./projects.html) to find the relevant documentation section.
4. For module work, review [module fundamentals](/openvox/latest/modules_fundamentals.html) and the
   [Puppet Forge](https://forge.puppet.com/).
