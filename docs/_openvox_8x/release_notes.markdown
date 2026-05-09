---
layout: default
toc_levels: 1234
title: "OpenVox 8 Release Notes"
---

This page lists the links to the changes in OpenVox 8 and its patch releases. You can also view [known issues](known_issues.html) in this release.

OpenVox's version numbers follows the [Semantic Versioning](https://semver.org/) schema, which splits a version into three segments: Major.Minor.Patch

- Major: must increase for major backward-incompatible changes
- Minor: can increase for backward-compatible new functionality or significant bug fixes
- Patch: can increase for bug fixes

## If you're upgrading from Puppet Open Source

Puppet Open Source is no longer actively developed.

You can either upgrade to Puppet 7 and then switch to OpenVox 7 and then upgrade to OpenVox 8, or you can upgrade to Puppet 8 and then migrate to OpenVox 8.

## OpenVox 8.26.2

Released April 18, 2026.

This is a bug-fix release of OpenVox.

All bug fixes, new features and other changes are provided on the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/8.26.2).

## OpenVox 8.26.1

Released April 16, 2026.

This is a bug-fix release of OpenVox.

All bug fixes, new features and other changes are provided on the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/8.26.1).

## OpenVox 8.26.0

Released April 14, 2026.

This is a bug-fix and security release of OpenVox.

All bug fixes, new features and other changes are provided on the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/8.26.0).

### Security Issues Resolved in 8.26.0

|===================================================================|============|=====================================|
|                            Identifier                             | CVSS Score |             Resolved By             |
|===================================================================|============|=====================================|
| [CVE-2026-27820](https://nvd.nist.gov/vuln/detail/CVE-2026-27820) |     N/A    |        `pkg:gem/zlib@3.0.1`         |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2026-3805](https://nvd.nist.gov/vuln/detail/CVE-2026-3805)   |     7.5    |    `pkg:github/curl/curl@8.19.0`    |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2026-1965](https://nvd.nist.gov/vuln/detail/CVE-2026-1965)   |     6.5    |    `pkg:github/curl/curl@8.19.0`    |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2026-3784](https://nvd.nist.gov/vuln/detail/CVE-2026-3784)   |     6.5    |    `pkg:github/curl/curl@8.19.0`    |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2026-3783](https://nvd.nist.gov/vuln/detail/CVE-2026-3783)   |     5.3    |    `pkg:github/curl/curl@8.19.0`    |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2026-31789](https://nvd.nist.gov/vuln/detail/CVE-2026-31789) |     9.8    | `pkg:github/openssl/openssl@3.0.20` |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2026-28387](https://nvd.nist.gov/vuln/detail/CVE-2026-28387) |     8.1    | `pkg:github/openssl/openssl@3.0.20` |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2026-28389](https://nvd.nist.gov/vuln/detail/CVE-2026-28389) |     7.5    | `pkg:github/openssl/openssl@3.0.20` |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2026-28390](https://nvd.nist.gov/vuln/detail/CVE-2026-28390) |     7.5    | `pkg:github/openssl/openssl@3.0.20` |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2026-28388](https://nvd.nist.gov/vuln/detail/CVE-2026-28388) |     7.5    | `pkg:github/openssl/openssl@3.0.20` |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2026-31790](https://nvd.nist.gov/vuln/detail/CVE-2026-31790) |     7.5    | `pkg:github/openssl/openssl@3.0.20` |
|===================================================================|============|=====================================|


## OpenVox 8.25.0

Released February 17, 2026.

This is a bug-fix and security release of OpenVox.

All bug fixes, new features and other changes are provided on the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/8.25.0).

### Security Issues Resolved in 8.25.0

|===================================================================|============|=====================================|
|                            Identifier                             | CVSS Score |             Resolved By             |
|===================================================================|============|=====================================|
| [CVE-2025-24294](https://nvd.nist.gov/vuln/detail/CVE-2025-24294) |     5.3    |       `pkg:gem/resolv@0.2.3`        |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2025-61594](https://nvd.nist.gov/vuln/detail/CVE-2025-61594) |     7.5    |        `pkg:gem/uri@0.12.5`         |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2025-14017](https://nvd.nist.gov/vuln/detail/CVE-2025-14017) |     6.3    |    `pkg:github/curl/curl@8.18.0`    |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2025-13034](https://nvd.nist.gov/vuln/detail/CVE-2025-13034) |     5.9    |    `pkg:github/curl/curl@8.18.0`    |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2025-14819](https://nvd.nist.gov/vuln/detail/CVE-2025-14819) |     5.3    |    `pkg:github/curl/curl@8.18.0`    |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2025-15079](https://nvd.nist.gov/vuln/detail/CVE-2025-15079) |     5.3    |    `pkg:github/curl/curl@8.18.0`    |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2025-14524](https://nvd.nist.gov/vuln/detail/CVE-2025-14524) |     5.3    |    `pkg:github/curl/curl@8.18.0`    |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2025-15224](https://nvd.nist.gov/vuln/detail/CVE-2025-15224) |     3.1    |    `pkg:github/curl/curl@8.18.0`    |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2025-15467](https://nvd.nist.gov/vuln/detail/CVE-2025-15467) |     8.8    | `pkg:github/openssl/openssl@3.0.19` |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2025-69420](https://nvd.nist.gov/vuln/detail/CVE-2025-69420) |     7.5    | `pkg:github/openssl/openssl@3.0.19` |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2025-69421](https://nvd.nist.gov/vuln/detail/CVE-2025-69421) |     7.5    | `pkg:github/openssl/openssl@3.0.19` |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2025-69419](https://nvd.nist.gov/vuln/detail/CVE-2025-69419) |     7.4    | `pkg:github/openssl/openssl@3.0.19` |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2026-22795](https://nvd.nist.gov/vuln/detail/CVE-2026-22795) |     5.5    | `pkg:github/openssl/openssl@3.0.19` |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2026-22796](https://nvd.nist.gov/vuln/detail/CVE-2026-22796) |     5.3    | `pkg:github/openssl/openssl@3.0.19` |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2025-68160](https://nvd.nist.gov/vuln/detail/CVE-2025-68160) |     4.7    | `pkg:github/openssl/openssl@3.0.19` |
|-------------------------------------------------------------------|------------|-------------------------------------|
| [CVE-2025-69418](https://nvd.nist.gov/vuln/detail/CVE-2025-69418) |      4     | `pkg:github/openssl/openssl@3.0.19` |
|===================================================================|============|=====================================|
