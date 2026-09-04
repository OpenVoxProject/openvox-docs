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

## OpenVox 8.29.0

Released September 4, 2026.

This is a bug-fix and security release of OpenVox.

All bug fixes, new features and other changes are provided on the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/8.29.0).

### Security Issues Resolved in 8.29.0

| Identifier                                                        | CVSS 3.1 Score | Resolved By                         |
| :---------------------------------------------------------------- | :------------: | :---------------------------------- |
| [CVE-2026-75803](https://nvd.nist.gov/vuln/detail/CVE-2026-75803) |       9.1      | `pkg:github/openssl/openssl@3.0.22` |
| [CVE-2026-54874](https://nvd.nist.gov/vuln/detail/CVE-2026-54874) |       7.5      | `pkg:github/openssl/openssl@3.0.22` |
| [CVE-2026-63072](https://nvd.nist.gov/vuln/detail/CVE-2026-63072) |       7.5      | `pkg:github/openssl/openssl@3.0.22` |
| [CVE-2026-63076](https://nvd.nist.gov/vuln/detail/CVE-2026-63076) |       7.5      | `pkg:github/openssl/openssl@3.0.22` |
| [CVE-2026-63074](https://nvd.nist.gov/vuln/detail/CVE-2026-63074) |       5.9      | `pkg:github/openssl/openssl@3.0.22` |
| [CVE-2026-19931](https://nvd.nist.gov/vuln/detail/CVE-2026-19931) |       N/A      | `pkg:github/curl/curl@8.22.0`       |
| [CVE-2026-13608](https://nvd.nist.gov/vuln/detail/CVE-2026-13608) |       N/A      | `pkg:github/curl/curl@8.22.0`       |
| [CVE-2026-18924](https://nvd.nist.gov/vuln/detail/CVE-2026-18924) |       N/A      | `pkg:github/curl/curl@8.22.0`       |
| [CVE-2026-80229](https://nvd.nist.gov/vuln/detail/CVE-2026-80229) |       N/A      | `pkg:github/curl/curl@8.22.0`       |
| [CVE-2026-80230](https://nvd.nist.gov/vuln/detail/CVE-2026-80230) |       N/A      | `pkg:github/curl/curl@8.22.0`       |
| [CVE-2026-80231](https://nvd.nist.gov/vuln/detail/CVE-2026-80231) |       N/A      | `pkg:github/curl/curl@8.22.0`       |
| [CVE-2026-80255](https://nvd.nist.gov/vuln/detail/CVE-2026-80255) |       N/A      | `pkg:github/curl/curl@8.22.0`       |
| [CVE-2026-82208](https://nvd.nist.gov/vuln/detail/CVE-2026-82208) |       N/A      | `pkg:github/curl/curl@8.22.0`       |
| [CVE-2026-82209](https://nvd.nist.gov/vuln/detail/CVE-2026-82209) |       N/A      | `pkg:github/curl/curl@8.22.0`       |

## OpenVox 8.28.1

Released July 8, 2026.

This is a bug-fix and security release of OpenVox.

All bug fixes, new features and other changes are provided on the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/8.28.1).

### Security Issues Resolved in 8.28.1

| Identifier                                                        | CVSS 3.1 Score | Resolved By                         |
| :---------------------------------------------------------------- | :------------: | :---------------------------------- |
| [CVE-2026-54906](https://nvd.nist.gov/vuln/detail/CVE-2026-54906) |       9.8      | `pkg:gem/concurrent-ruby@1.3.7`     |
| [CVE-2026-54904](https://nvd.nist.gov/vuln/detail/CVE-2026-54904) |       7.5      | `pkg:gem/concurrent-ruby@1.3.7`     |
| [CVE-2026-54905](https://nvd.nist.gov/vuln/detail/CVE-2026-54905) |       5.5      | `pkg:gem/concurrent-ruby@1.3.7`     |
| [CVE-2026-47242](https://nvd.nist.gov/vuln/detail/CVE-2026-47242) |       N/A      | `pkg:gem/net-imap@0.6.4.1`          |
| [CVE-2026-47241](https://nvd.nist.gov/vuln/detail/CVE-2026-47241) |       N/A      | `pkg:gem/net-imap@0.6.4.1`          |
| [CVE-2026-47240](https://nvd.nist.gov/vuln/detail/CVE-2026-47240) |       N/A      | `pkg:gem/net-imap@0.6.4.1`          |
| [CVE-2026-8804](https://nvd.nist.gov/vuln/detail/CVE-2026-8804)   |       6.7      | `pkg:gem/puppet-resource_api@1.9.2` |
| [CVE-2026-8925](https://nvd.nist.gov/vuln/detail/CVE-2026-8925)   |       9.8      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-11856](https://nvd.nist.gov/vuln/detail/CVE-2026-11856) |       9.8      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-9079](https://nvd.nist.gov/vuln/detail/CVE-2026-9079)   |       9.8      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-10536](https://nvd.nist.gov/vuln/detail/CVE-2026-10536) |       9.8      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-8927](https://nvd.nist.gov/vuln/detail/CVE-2026-8927)   |       9.1      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-8924](https://nvd.nist.gov/vuln/detail/CVE-2026-8924)   |       9.1      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-11564](https://nvd.nist.gov/vuln/detail/CVE-2026-11564) |       9.1      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-8926](https://nvd.nist.gov/vuln/detail/CVE-2026-8926)   |       9.1      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-8286](https://nvd.nist.gov/vuln/detail/CVE-2026-8286)   |       8.1      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-11352](https://nvd.nist.gov/vuln/detail/CVE-2026-11352) |       7.5      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-11586](https://nvd.nist.gov/vuln/detail/CVE-2026-11586) |       7.5      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-9546](https://nvd.nist.gov/vuln/detail/CVE-2026-9546)   |       7.5      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-12064](https://nvd.nist.gov/vuln/detail/CVE-2026-12064) |       7.5      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-9545](https://nvd.nist.gov/vuln/detail/CVE-2026-9545)   |       7.5      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-8932](https://nvd.nist.gov/vuln/detail/CVE-2026-8932)   |       7.5      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-9547](https://nvd.nist.gov/vuln/detail/CVE-2026-9547)   |       7.4      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-9080](https://nvd.nist.gov/vuln/detail/CVE-2026-9080)   |       7.3      | `pkg:github/curl/curl@8.21.0`       |
| [CVE-2026-8458](https://nvd.nist.gov/vuln/detail/CVE-2026-8458)   |       6.5      | `pkg:github/curl/curl@8.21.0`       |

## OpenVox 8.28.0

Released June 10, 2026.

This is a bug-fix and security release of OpenVox.

All bug fixes, new features and other changes are provided on the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/8.28.0).

### Security Issues Resolved in 8.28.0

|                            Identifier                             | CVSS 3.1 Score |             Resolved By             |
| ----------------------------------------------------------------- | :------------: | ----------------------------------- |
| [CVE-2026-34182](https://nvd.nist.gov/vuln/detail/CVE-2026-34182) |      9.1       | `pkg:github/openssl/openssl@3.0.21` |
| [CVE-2026-45447](https://nvd.nist.gov/vuln/detail/CVE-2026-45447) |      8.8       | `pkg:github/openssl/openssl@3.0.21` |
| [CVE-2026-7383](https://nvd.nist.gov/vuln/detail/CVE-2026-7383)   |      8.1       | `pkg:github/openssl/openssl@3.0.21` |
| [CVE-2026-45445](https://nvd.nist.gov/vuln/detail/CVE-2026-45445) |      7.5       | `pkg:github/openssl/openssl@3.0.21` |
| [CVE-2026-34180](https://nvd.nist.gov/vuln/detail/CVE-2026-34180) |      7.5       | `pkg:github/openssl/openssl@3.0.21` |
| [CVE-2026-9076](https://nvd.nist.gov/vuln/detail/CVE-2026-9076)   |      7.5       | `pkg:github/openssl/openssl@3.0.21` |
| [CVE-2026-42766](https://nvd.nist.gov/vuln/detail/CVE-2026-42766) |      5.9       | `pkg:github/openssl/openssl@3.0.21` |
| [CVE-2026-45446](https://nvd.nist.gov/vuln/detail/CVE-2026-45446) |      4.8       | `pkg:github/openssl/openssl@3.0.21` |
| [CVE-2026-42770](https://nvd.nist.gov/vuln/detail/CVE-2026-42770) |      3.7       | `pkg:github/openssl/openssl@3.0.21` |


## OpenVox 8.27.0

Released May 18, 2026.

This is a bug-fix and security release of OpenVox.

All bug fixes, new features and other changes are provided on the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/8.27.0).

### Security Issues Resolved in 8.27.0

|                                Identifier                         | CVSS 3.1 Score |            Resolved By            |
|-------------------------------------------------------------------| :------------: |-----------------------------------|
| [CVE-2026-41316](https://nvd.nist.gov/vuln/detail/CVE-2026-41316) |      8.1       | `pkg:gem/erb@4.0.3.1`             |
| [CVE-2026-42258](https://nvd.nist.gov/vuln/detail/CVE-2026-42258) |      9.8       | `pkg:gem/net-imap@0.4.24`         |
| [CVE-2026-42257](https://nvd.nist.gov/vuln/detail/CVE-2026-42257) |      9.8       | `pkg:gem/net-imap@0.4.24`         |
| [CVE-2026-42245](https://nvd.nist.gov/vuln/detail/CVE-2026-42245) |      7.5       | `pkg:gem/net-imap@0.4.24`         |
| [CVE-2026-42246](https://nvd.nist.gov/vuln/detail/CVE-2026-42246) |      7.4       | `pkg:gem/net-imap@0.4.24`         |
| [CVE-2026-5773](https://nvd.nist.gov/vuln/detail/CVE-2026-5773)   |      7.5       | `pkg:github/curl/curl@8.20.0`     |
| [CVE-2026-6276](https://nvd.nist.gov/vuln/detail/CVE-2026-6276)   |      7.5       | `pkg:github/curl/curl@8.20.0`     |
| [CVE-2026-5545](https://nvd.nist.gov/vuln/detail/CVE-2026-5545)   |      6.5       | `pkg:github/curl/curl@8.20.0`     |
| [CVE-2026-6253](https://nvd.nist.gov/vuln/detail/CVE-2026-6253)   |      5.9       | `pkg:github/curl/curl@8.20.0`     |
| [CVE-2026-4873](https://nvd.nist.gov/vuln/detail/CVE-2026-4873)   |      5.9       | `pkg:github/curl/curl@8.20.0`     |
| [CVE-2026-7168](https://nvd.nist.gov/vuln/detail/CVE-2026-7168)   |      5.3       | `pkg:github/curl/curl@8.20.0`     |
| [CVE-2026-6429](https://nvd.nist.gov/vuln/detail/CVE-2026-6429)   |      5.3       | `pkg:github/curl/curl@8.20.0`     |
| [CVE-2026-7009](https://nvd.nist.gov/vuln/detail/CVE-2026-7009)   |      5.3       | `pkg:github/curl/curl@8.20.0`     |
| [CVE-2026-6732](https://nvd.nist.gov/vuln/detail/CVE-2026-6732)   |      7.5       | `pkg:github/gnome/libxml2@2.15.3` |


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

|                            Identifier                             | CVSS 3.1 Score |             Resolved By             |
| ----------------------------------------------------------------- | :------------: | ----------------------------------- |
| [CVE-2026-27820](https://nvd.nist.gov/vuln/detail/CVE-2026-27820) |      9.8       | `pkg:gem/zlib@3.0.1`                |
| [CVE-2026-3805](https://nvd.nist.gov/vuln/detail/CVE-2026-3805)   |      7.5       | `pkg:github/curl/curl@8.19.0`       |
| [CVE-2026-1965](https://nvd.nist.gov/vuln/detail/CVE-2026-1965)   |      6.5       | `pkg:github/curl/curl@8.19.0`       |
| [CVE-2026-3784](https://nvd.nist.gov/vuln/detail/CVE-2026-3784)   |      6.5       | `pkg:github/curl/curl@8.19.0`       |
| [CVE-2026-3783](https://nvd.nist.gov/vuln/detail/CVE-2026-3783)   |      5.3       | `pkg:github/curl/curl@8.19.0`       |
| [CVE-2026-31789](https://nvd.nist.gov/vuln/detail/CVE-2026-31789) |      9.8       | `pkg:github/openssl/openssl@3.0.20` |
| [CVE-2026-28387](https://nvd.nist.gov/vuln/detail/CVE-2026-28387) |      8.1       | `pkg:github/openssl/openssl@3.0.20` |
| [CVE-2026-28389](https://nvd.nist.gov/vuln/detail/CVE-2026-28389) |      7.5       | `pkg:github/openssl/openssl@3.0.20` |
| [CVE-2026-28390](https://nvd.nist.gov/vuln/detail/CVE-2026-28390) |      7.5       | `pkg:github/openssl/openssl@3.0.20` |
| [CVE-2026-28388](https://nvd.nist.gov/vuln/detail/CVE-2026-28388) |      7.5       | `pkg:github/openssl/openssl@3.0.20` |
| [CVE-2026-31790](https://nvd.nist.gov/vuln/detail/CVE-2026-31790) |      7.5       | `pkg:github/openssl/openssl@3.0.20` |


## OpenVox 8.25.0

Released February 17, 2026.

This is a bug-fix and security release of OpenVox.

All bug fixes, new features and other changes are provided on the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/8.25.0).

### Security Issues Resolved in 8.25.0

|                            Identifier                             | CVSS 3.1 Score |             Resolved By             |
| ----------------------------------------------------------------- | :------------: | ----------------------------------- |
| [CVE-2025-24294](https://nvd.nist.gov/vuln/detail/CVE-2025-24294) |      5.3       | `pkg:gem/resolv@0.2.3`              |
| [CVE-2025-61594](https://nvd.nist.gov/vuln/detail/CVE-2025-61594) |      7.5       | `pkg:gem/uri@0.12.5`                |
| [CVE-2025-14017](https://nvd.nist.gov/vuln/detail/CVE-2025-14017) |      6.3       | `pkg:github/curl/curl@8.18.0`       |
| [CVE-2025-13034](https://nvd.nist.gov/vuln/detail/CVE-2025-13034) |      5.9       | `pkg:github/curl/curl@8.18.0`       |
| [CVE-2025-14819](https://nvd.nist.gov/vuln/detail/CVE-2025-14819) |      5.3       | `pkg:github/curl/curl@8.18.0`       |
| [CVE-2025-15079](https://nvd.nist.gov/vuln/detail/CVE-2025-15079) |      5.3       | `pkg:github/curl/curl@8.18.0`       |
| [CVE-2025-14524](https://nvd.nist.gov/vuln/detail/CVE-2025-14524) |      5.3       | `pkg:github/curl/curl@8.18.0`       |
| [CVE-2025-15224](https://nvd.nist.gov/vuln/detail/CVE-2025-15224) |      3.1       | `pkg:github/curl/curl@8.18.0`       |
| [CVE-2025-15467](https://nvd.nist.gov/vuln/detail/CVE-2025-15467) |      8.8       | `pkg:github/openssl/openssl@3.0.19` |
| [CVE-2025-69419](https://nvd.nist.gov/vuln/detail/CVE-2025-69419) |      7.4       | `pkg:github/openssl/openssl@3.0.19` |
| [CVE-2026-22795](https://nvd.nist.gov/vuln/detail/CVE-2026-22795) |      5.5       | `pkg:github/openssl/openssl@3.0.19` |
| [CVE-2026-22796](https://nvd.nist.gov/vuln/detail/CVE-2026-22796) |      5.3       | `pkg:github/openssl/openssl@3.0.19` |
| [CVE-2025-68160](https://nvd.nist.gov/vuln/detail/CVE-2025-68160) |      4.7       | `pkg:github/openssl/openssl@3.0.19` |
| [CVE-2025-69418](https://nvd.nist.gov/vuln/detail/CVE-2025-69418) |      4.0       | `pkg:github/openssl/openssl@3.0.19` |
