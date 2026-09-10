---
title: "OpenVoxDB 9 Release Notes"
layout: default
---

# OpenVoxDB 9 Release Notes

> **OpenVoxDB 9 is in prerelease.** This page tracks the beta and release-candidate
> builds ahead of the stable 9.0.0 release. Expect breaking changes between prereleases; see
> [known issues](./known_issues.html) for anything discovered so far.

OpenVoxDB 9 is released alongside OpenVox 9 and OpenVox Server 9. For the changes on
those components, see the [OpenVox 9 release notes](/openvox/9.x/release_notes.html)
and the [OpenVox Server 9 release notes](/openvox-server/9.x/release_notes.html).

## OpenVoxDB 9.0.0-rc1

Released September 9, 2026.

This is the first **release candidate** of OpenVoxDB 9 and is not yet the stable
release. See the
[project's GitHub release page](https://github.com/OpenVoxProject/openvoxdb/releases/tag/9.0.0-rc1)
for the full list of changes.

Notable breaking changes in this build:

- Packages are now built with EZbake 4.1.0. The systemd unit starts the JVM directly
  with the Java binary chosen at package build time, so the `JAVA_BIN` variable in
  `/etc/sysconfig/puppetdb` or `/etc/default/puppetdb` is no longer used. `JAVA_ARGS`
  still applies. The unit uses systemd's `notify` protocol (`Type=notify`, or
  `Type=notify-reload` where systemd 253 or newer is available), so systemd reports
  the service as started only after OpenVoxDB is fully up. Packages depend on a
  Java 25 runtime where the platform provides one and on Java 21 otherwise.
- The `openvoxdb` and `openvoxdb-termini` packages now require `openvox-agent`
  9.0.0-beta1 or later. The beta1 packages had no upper bound and installed alongside
  an 8.x agent; the release candidate does not.

Other notable changes:

- Two new `puppetdb.conf` settings, `fact_names_blocklist` and
  `fact_names_blocklist_regex`, let the termini drop facts, including individual keys
  inside structured facts, before they are sent to OpenVoxDB. See
  [Configuring a Puppet/OpenVoxDB connection](./puppetdb_connection.html#fact_names_blocklist).
- Fixed a query planner error for `nodes` queries that filter on `report_environment`
  while extracting only `certname`.
- Dependency updates across the Trapperkeeper stack, plus Jackson 2.21.6, logback
  1.6.3, and Clojure 1.12.6.

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
