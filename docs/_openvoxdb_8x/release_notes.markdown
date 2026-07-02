---
title: "OpenVoxDB 8 Release Notes"
layout: default
canonical: "/openvoxdb/latest/release_notes.html"
---

# OpenVoxDB 8 Release Notes

## OpenVoxDB 8.14.1

Released June 25, 2026.

This is a bug-fix release of OpenVoxDB.

All bug fixes, new features and other changes are provided on the
[project's GitHub release page](https://github.com/OpenVoxProject/openvoxdb/releases/tag/8.14.1).

### Known Issues in 8.14.1

#### `puppetdb` service can fail to start after upgrade to OpenVoxDB 8.14.1

The 8.14.1 release contains a major update to the Jetty component, moving from version 10 to 12. This is accompanied by a change in the `/etc/puppetlabs/puppetdb/bootstrap.cfg` file that instructs the `puppetdb` service to load `jetty-service` instead of the older `jetty10-service`.

The `bootstrap.cfg` file is marked as a "configuration file", which means package managers will skip updating it with new content  if the file has been modified. If the update is skipped, the old configuration specifying `jetty10-service` is retained and the `puppetdb` service fails to start or restart after the upgrade.

When this occurs, the following warning is printed to `/var/log/puppetlabs/puppetdb/puppetdb.log`:

```console
2026-06-26T16:41:56.598Z WARN  [p.t.bootstrap] Unable to load service 'puppetlabs.trapperkeeper.services.webserver.jetty10-service/jetty10-service' from /etc/puppetlabs/puppetdb/bootstrap.cfg:7
```

The service start failure can be fixed by editing `bootstrap.cfg` and replacing `jetty10-service` with `jetty-service`:

```diff
# diff -u /etc/puppetlabs/puppetdb/bootstrap.cfg*
--- /etc/puppetlabs/puppetdb/bootstrap.cfg      2026-06-26 16:38:50.416748668 +0000
+++ /etc/puppetlabs/puppetdb/bootstrap.cfg.rpmnew       2026-06-24 21:10:12.000000000 +0000
@@ -4,7 +4,7 @@
 #  https://github.com/puppetlabs/trapperkeeper/wiki/Bootstrapping

 # Web Server
-puppetlabs.trapperkeeper.services.webserver.jetty10-service/jetty10-service
+puppetlabs.trapperkeeper.services.webserver.jetty-service/jetty-service

 # Webrouting
 puppetlabs.trapperkeeper.services.webrouting.webrouting-service/webrouting-service
```

## OpenVoxDB 8.14.0

{% include alert.html type="note" title="Unreleased" content="Packages for version 8.14.0 were not released due to broken APIs for monitoring service status and performance." %}

This is an enhancement, bug-fix, and security release of OpenVoxDB.

All bug fixes, new features and other changes are provided on the [project's GitHub release page](https://github.com/OpenVoxProject/openvoxdb/releases/tag/8.14.0).

### Security Issues Resolved in 8.14.0

| Identifier                                                        | CVSS 3.1 Score | Resolved By                                           |
| :---------------------------------------------------------------- | :------------: | :---------------------------------------------------- |
| [CVE-2026-2332](https://nvd.nist.gov/vuln/detail/CVE-2026-2332)   |       9.1      | `pkg:maven/org.eclipse.jetty/jetty-http@12.1.9`       |
| [CVE-2025-11143](https://nvd.nist.gov/vuln/detail/CVE-2025-11143) |       6.5      | `pkg:maven/org.eclipse.jetty/jetty-http@12.1.9`       |
| [CVE-2024-6763](https://nvd.nist.gov/vuln/detail/CVE-2024-6763)   |       5.3      | `pkg:maven/org.eclipse.jetty/jetty-http@12.1.9`       |
| [CVE-2026-1225](https://nvd.nist.gov/vuln/detail/CVE-2026-1225)   |       N/A      | `pkg:maven/ch.qos.logback/logback-core@1.5.32`        |

## OpenVoxDB 8.13.0

Released May 4, 2026.

This is an enhancement release of OpenVoxDB.

All bug fixes, new features and other changes are provided on the
[project's GitHub release page](https://github.com/OpenVoxProject/openvoxdb/releases/tag/8.13.0).

### Security Issues Resolved in 8.13.0

| Identifier                                                               | CVSS 3.1 Score | Resolved By                                                |
| :----------------------------------------------------------------------- | :------------: | :--------------------------------------------------------- |
| [GHSA-72hv-8253-57qq](https://github.com/advisories/GHSA-72hv-8253-57qq) |       N/A      | `pkg:maven/com.fasterxml.jackson.core/jackson-core@2.21.3` |
| [CVE-2025-67721](https://nvd.nist.gov/vuln/detail/CVE-2025-67721)        |       7.5      | `pkg:maven/io.airlift/aircompressor@2.0.3`                 |
| [CVE-2026-42198](https://nvd.nist.gov/vuln/detail/CVE-2026-42198)        |       7.5      | `pkg:maven/org.postgresql/postgresql@42.7.11`              |

## OpenVoxDB 8.12.1

Released January 23, 2026.

This is a bug-fix release of OpenVoxDB.

All bug fixes, new features and other changes are provided on the
[project's GitHub release page](https://github.com/OpenVoxProject/openvoxdb/releases/tag/8.12.1).

## OpenVoxDB 8.12.0

Released January 23, 2026.

This is a bug-fix and enhancement release of OpenVoxDB.

All bug fixes, new features and other changes are provided on the
[project's GitHub release page](https://github.com/OpenVoxProject/openvoxdb/releases/tag/8.12.0).

## OpenVoxDB 8.11.0

Released August 24, 2025.

This is a maintenance release of OpenVoxDB.

All bug fixes, new features and other changes are provided on the
[project's GitHub release page](https://github.com/OpenVoxProject/openvoxdb/releases/tag/8.11.0).

## OpenVoxDB 8.10.0

Released August 4, 2025.

This is an enhancement release of OpenVoxDB.

All bug fixes, new features and other changes are provided on the
[project's GitHub release page](https://github.com/OpenVoxProject/openvoxdb/releases/tag/8.10.0).

## OpenVoxDB 8.9.1

* Added `Obsoletes`, `Replaces`, and `Conflicts` package metadata for
  `puppetdb` and `puppetdb-termini` to the `openvoxdb` and
  `openvoxdb-termini` packages to support clean upgrades.

## OpenVoxDB 8.9.0

This is the initial OpenVoxDB release, based on PuppetDB 8.8.1 and supported
on all platforms that PuppetDB supported, but for all architectures rather than
just x86_64.
