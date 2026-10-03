---
title: "OpenVoxDB 9 Release Notes"
layout: default
---

# OpenVoxDB 9 Release Notes

OpenVoxDB 9 is released alongside OpenVox 9 and OpenVox Server 9. For the changes on
those components, see the [OpenVox 9 release notes](/openvox/9.x/release_notes.html)
and the [OpenVox Server 9 release notes](/openvox-server/9.x/release_notes.html).

## OpenVoxDB 9.0.0

Released October 2, 2026.

This is the first stable release of OpenVoxDB 9. See the
[project's GitHub release page](https://github.com/OpenVoxProject/openvoxdb/releases/tag/9.0.0)
for the full list of changes, and the [OpenVox 9 release notes](/openvox/9.x/release_notes.html)
for the agent-side changes, including the "Upgrading from OpenVox 8" checklist linked
from there.

Breaking changes compared with OpenVoxDB 8:

- **Java 21 or 25 is required.** The package depends on a Java 25 or Java 21 runtime
  package and prefers Java 25 wherever the platform provides it; Enterprise Linux 8
  provides Java 21 only. The FIPS packages run on Java 21 only. Java 17 is no longer
  supported.
- **The systemd unit runs the JVM directly.** It starts
  `/opt/puppetlabs/server/apps/puppetdb/bin/java`, a launcher that runs the first installed
  Java from the supported list (25, then 21), and reports readiness to systemd
  (`Type=notify`, or `Type=notify-reload` on systemd 253 or newer). The `puppetdb start`
  and `puppetdb stop` subcommands are removed; use `systemctl`. `JAVA_BIN` in
  `/etc/sysconfig/puppetdb` or `/etc/default/puppetdb` is only needed to override the
  launcher, and a `JAVA_BIN="/usr/bin/java"` line left over from an 8.x install is
  ignored. `JAVA_ARGS` still applies. See [Configuring OpenVoxDB](./configure.html).
- **The embedded web server is Jetty 12.** If you upgraded from OpenVoxDB 8.14.0 or
  earlier with a modified `/etc/puppetlabs/puppetdb/bootstrap.cfg`, the package manager
  keeps your copy and the service fails to start because the old file loads
  `jetty10-service`. Replace that line with
  `puppetlabs.trapperkeeper.services.webserver.jetty-service/jetty-service` (see the
  8.14.1 entry in the [OpenVoxDB 8 release notes](/openvoxdb/8.x/release_notes.html)).
- **The `openvoxdb` package requires `openvox-agent` 9.0.0 or newer** on the same host.
  The `openvoxdb-termini` package depends on `openvox-agent` without a version.
- **Platforms.** Packages are no longer built for Debian 11, Debian 12, Ubuntu 25.04,
  Amazon Linux 2, or Fedora 42; see
  [Supported platforms](/openvox/9.x/supported_platforms.html).

Other notable changes:

- Two new `puppetdb.conf` settings, `fact_names_blocklist` and
  `fact_names_blocklist_regex`, let the termini drop facts, including individual keys
  inside structured facts, before they are sent to OpenVoxDB. Invalid expressions are
  rejected when `puppetdb.conf` is loaded. See
  [Configuring a Puppet/OpenVoxDB connection](./puppetdb_connection.html#fact_names_blocklist).
- `puppetdb ssl-setup` no longer calls `puppet agent --configprint`, which the OpenVox 9
  agent removed.
- The published source tarball contains the complete uberjar again; the 8.16.0 and
  9.0.0-rc1 tarballs were missing files.
- The `openvoxdb-terminus` gem allows openvox 9.

### Security issues resolved in 9.0.0

Compared with OpenVoxDB 8.16.0. The Bouncy Castle scores are CVSS 4.0 base scores from
NVD; the project's release page lists them as not yet scored.

| Identifier                                                        | CVSS Score | Resolved By                                                             |
| :---------------------------------------------------------------- | :--------: | :---------------------------------------------------------------------- |
| [CVE-2026-71885](https://nvd.nist.gov/vuln/detail/CVE-2026-71885) |    9.2     | `pkg:maven/org.bouncycastle/bcpkix-jdk18on@1.86`                        |
| [CVE-2026-17507](https://nvd.nist.gov/vuln/detail/CVE-2026-17507) |    8.7     | `pkg:maven/org.bouncycastle/bcpkix-jdk18on@1.86`                        |
| [CVE-2026-71888](https://nvd.nist.gov/vuln/detail/CVE-2026-71888) |    8.7     | `pkg:maven/org.bouncycastle/bcpkix-jdk18on@1.86`                        |
| [CVE-2026-71889](https://nvd.nist.gov/vuln/detail/CVE-2026-71889) |    8.7     | `pkg:maven/org.bouncycastle/bcpkix-jdk18on@1.86`                        |
| [CVE-2026-71890](https://nvd.nist.gov/vuln/detail/CVE-2026-71890) |    8.7     | `pkg:maven/org.bouncycastle/bcpkix-jdk18on@1.86`                        |
| [CVE-2026-18036](https://nvd.nist.gov/vuln/detail/CVE-2026-18036) |    8.2     | `pkg:maven/org.bouncycastle/bcpkix-jdk18on@1.86`                        |
| [CVE-2026-71886](https://nvd.nist.gov/vuln/detail/CVE-2026-71886) |    8.2     | `pkg:maven/org.bouncycastle/bcpkix-jdk18on@1.86`                        |
| [CVE-2026-71887](https://nvd.nist.gov/vuln/detail/CVE-2026-71887) |    8.2     | `pkg:maven/org.bouncycastle/bcpkix-jdk18on@1.86`                        |
| [CVE-2026-85515](https://nvd.nist.gov/vuln/detail/CVE-2026-85515) |    8.2     | `pkg:maven/org.bouncycastle/bcpkix-jdk18on@1.86`                        |
| [CVE-2026-89407](https://nvd.nist.gov/vuln/detail/CVE-2026-89407) |    7.5     | `pkg:maven/com.fasterxml.jackson.core/jackson-core@2.21.7`              |
| [CVE-2026-89425](https://nvd.nist.gov/vuln/detail/CVE-2026-89425) |    7.5     | `pkg:maven/com.fasterxml.jackson.core/jackson-core@2.21.7`              |
| [CVE-2026-91776](https://nvd.nist.gov/vuln/detail/CVE-2026-91776) |    7.5     | `pkg:maven/com.fasterxml.jackson.core/jackson-databind@2.21.7`          |
| [CVE-2026-91777](https://nvd.nist.gov/vuln/detail/CVE-2026-91777) |    7.5     | `pkg:maven/com.fasterxml.jackson.core/jackson-databind@2.21.7`          |
| [CVE-2026-71891](https://nvd.nist.gov/vuln/detail/CVE-2026-71891) |    7.1     | `pkg:maven/org.bouncycastle/bcpkix-jdk18on@1.86`                        |
| [CVE-2026-71892](https://nvd.nist.gov/vuln/detail/CVE-2026-71892) |    6.9     | `pkg:maven/org.bouncycastle/bcpkix-jdk18on@1.86`                        |
| [CVE-2026-18040](https://nvd.nist.gov/vuln/detail/CVE-2026-18040) |    5.9     | `pkg:maven/org.bouncycastle/bcpkix-jdk18on@1.86`                        |
| [CVE-2026-17508](https://nvd.nist.gov/vuln/detail/CVE-2026-17508) |    5.3     | `pkg:maven/org.bouncycastle/bcpkix-jdk18on@1.86`                        |

## OpenVoxDB 9.0.0-rc2

Released September 29, 2026.

This was the last release candidate before 9.0.0. See the
[project's GitHub release page](https://github.com/OpenVoxProject/openvoxdb/releases/tag/9.0.0-rc2)
for the full list of changes.

Notable changes in this build:

- Packages are built with EZbake 4.2.0. The systemd unit starts the JVM through the
  `bin/java` launcher described in the 9.0.0 entry, which runs the first installed Java
  from the supported list and honors `JAVA_BIN` from the defaults file when it points at
  a supported version. This replaces the 9.0.0-rc1 behavior of running the Java binary
  chosen at package build time.
- The FIPS source tarballs are named correctly.
- Bouncy Castle 1.86, Jackson 2.21.7, logback 1.6.4, and other dependency updates.

## OpenVoxDB 9.0.0-rc1

Released September 9, 2026.

This was the first **release candidate** of OpenVoxDB 9. See the
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
- The `openvoxdb` package now requires `openvox-agent` 9.0.0-beta1 or later. The
  beta1 package had no upper bound and installed alongside an 8.x agent; the release
  candidate does not. The `openvoxdb-termini` package still depends on
  `openvox-agent` without a version.

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

This was a **prerelease** of OpenVoxDB 9. It includes
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
