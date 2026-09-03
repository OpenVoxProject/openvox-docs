---
title: "OpenVoxDB 9 Release Notes"
layout: default
---

# OpenVoxDB 9 Release Notes

> **OpenVoxDB 9 is in prerelease.** This page tracks the beta builds ahead of the
> stable 9.0.0 release. Expect breaking changes between prereleases; see
> [known issues](./known_issues.html) for anything discovered so far.

OpenVoxDB 9 is released alongside OpenVox 9 and OpenVox Server 9. For the changes on
those components, see the [OpenVox 9 release notes](/openvox/9.x/release_notes.html)
and the [OpenVox Server 9 release notes](/openvox-server/9.x/release_notes.html).

## OpenVoxDB 9.0.0-beta1

Released July 15, 2026.

This is a **prerelease** of OpenVoxDB 9 and is not yet the stable release. It includes
breaking changes; see the
[project's GitHub release page](https://github.com/OpenVoxProject/openvoxdb/releases/tag/9.0.0-beta1)
for the full list of changes.

Notable breaking changes in this build:

- Java 21 or 25 is required. Java 17 is no longer supported.
- The embedded web server is upgraded to Jetty 12. If you upgrade from OpenVoxDB
  8.14.0 or earlier and have modified `/etc/puppetlabs/puppetdb/bootstrap.cfg`, the
  package manager keeps your copy, and the service fails to start because the old
  file loads `jetty10-service`. Replace that line with
  `puppetlabs.trapperkeeper.services.webserver.jetty-service/jetty-service` (see the
  8.14.1 entry in the [OpenVoxDB 8 release notes](/openvoxdb/8.x/release_notes.html)
  for the full diff).
- Packages are no longer built for Debian 11 and Debian 12.

Other notable changes:

- `puppetdb ssl-setup` no longer calls `puppet agent --configprint`, which was removed
  from the OpenVox 9 agent.
- Fixed the Jolokia 2.x configuration for the [v2 metrics API](./api/metrics/v2/jolokia.html).
- The `openvoxdb` and `openvoxdb-termini` packages depend on `openvox-agent` 8.26.2 or
  later, with no upper bound, so they install alongside either an 8.x or a 9.x agent.
- This build branched from 8.13.0 and carries the dependency updates that resolved the
  8.15.0 advisories (`jackson` 2.21.5 and the PostgreSQL JDBC driver 42.7.13).
