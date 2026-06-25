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
