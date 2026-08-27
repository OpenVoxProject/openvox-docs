---
layout: default
toc_levels: 1234
title: "OpenVox 9 Release Notes"
---

> **OpenVox 9 is in prerelease.** This page tracks the alpha and beta builds ahead of
> the stable 9.0.0 release. Expect breaking changes between prereleases; see
> [known issues](known_issues.html) for anything discovered so far.

This page lists the links to the changes in OpenVox 9 and its prereleases. You can also view [known issues](known_issues.html) in this release.

OpenVox's version numbers follows the [Semantic Versioning](https://semver.org/) schema, which splits a version into three segments: Major.Minor.Patch

- Major: must increase for major backward-incompatible changes
- Minor: can increase for backward-compatible new functionality or significant bug fixes
- Patch: can increase for bug fixes

## If you're upgrading from Puppet Open Source

Puppet Open Source is no longer actively developed.

You can either upgrade to Puppet 7 and then switch to OpenVox 7 and then upgrade through OpenVox 8 to OpenVox 9, or you can upgrade to Puppet 8 and then migrate to OpenVox 8 and then to OpenVox 9.

## OpenVox 9.0.0-beta2

Released August 6, 2026.

This is a **prerelease** of OpenVox 9 and is not yet the stable release. It includes breaking changes; see the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/9.0.0-beta2) for the full list of changes.

Notable breaking changes in this build:

- The default for the [`reports` setting](configuration.html#reports) changed from `store` to `none`, so report processing is now opt-in.
- OpenFact 6.x is now required.
- The deprecated `hiera` indirector and the data-binding settings have been removed.
- The `zone_core` vendored module has been removed.
- Java keystores have been removed from the runtime.

## OpenVox 9.0.0-beta1

Released July 15, 2026.

This is a **prerelease** of OpenVox 9 and is not yet the stable release. It includes breaking changes; see the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/9.0.0-beta1) for the full list of changes.

### Security Issues Resolved in 9.0.0-beta1

| Identifier                                                        | CVSS 3.1 Score | Resolved By                     |
| :------------------------------------------------------------------ | :------------: | :--------------------------------- |
| [CVE-2026-54906](https://nvd.nist.gov/vuln/detail/CVE-2026-54906) |       9.8       | `pkg:gem/concurrent-ruby@1.3.7` |
| [CVE-2026-54904](https://nvd.nist.gov/vuln/detail/CVE-2026-54904) |       7.5       | `pkg:gem/concurrent-ruby@1.3.7` |
| [CVE-2026-54905](https://nvd.nist.gov/vuln/detail/CVE-2026-54905) |       5.5       | `pkg:gem/concurrent-ruby@1.3.7` |

## OpenVox 9.0.0-alpha2

Released June 10, 2026.

This is a **prerelease** of OpenVox 9 and is not yet the stable release. It includes breaking changes; see the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/9.0.0-alpha2) for the full list of changes.

### Security Issues Resolved in 9.0.0-alpha2

| Identifier                                                        | CVSS 3.1 Score | Resolved By                       |
| :------------------------------------------------------------------ | :------------: | :----------------------------------- |
| [CVE-2026-34182](https://nvd.nist.gov/vuln/detail/CVE-2026-34182) |       9.1       | `pkg:github/openssl/openssl@3.5.7` |
| [CVE-2026-45447](https://nvd.nist.gov/vuln/detail/CVE-2026-45447) |       8.8       | `pkg:github/openssl/openssl@3.5.7` |
| [CVE-2026-7383](https://nvd.nist.gov/vuln/detail/CVE-2026-7383)   |       8.1       | `pkg:github/openssl/openssl@3.5.7` |
| [CVE-2026-45445](https://nvd.nist.gov/vuln/detail/CVE-2026-45445) |       7.5       | `pkg:github/openssl/openssl@3.5.7` |
| [CVE-2026-42764](https://nvd.nist.gov/vuln/detail/CVE-2026-42764) |       7.5       | `pkg:github/openssl/openssl@3.5.7` |
| [CVE-2026-34183](https://nvd.nist.gov/vuln/detail/CVE-2026-34183) |       7.5       | `pkg:github/openssl/openssl@3.5.7` |
| [CVE-2026-34180](https://nvd.nist.gov/vuln/detail/CVE-2026-34180) |       7.5       | `pkg:github/openssl/openssl@3.5.7` |
| [CVE-2026-9076](https://nvd.nist.gov/vuln/detail/CVE-2026-9076)   |       7.5       | `pkg:github/openssl/openssl@3.5.7` |
| [CVE-2026-34181](https://nvd.nist.gov/vuln/detail/CVE-2026-34181) |       7.4       | `pkg:github/openssl/openssl@3.5.7` |
| [CVE-2026-42767](https://nvd.nist.gov/vuln/detail/CVE-2026-42767) |       5.9       | `pkg:github/openssl/openssl@3.5.7` |
| [CVE-2026-42766](https://nvd.nist.gov/vuln/detail/CVE-2026-42766) |       5.9       | `pkg:github/openssl/openssl@3.5.7` |
| [CVE-2026-42769](https://nvd.nist.gov/vuln/detail/CVE-2026-42769) |       5.3       | `pkg:github/openssl/openssl@3.5.7` |
| [CVE-2026-45446](https://nvd.nist.gov/vuln/detail/CVE-2026-45446) |       4.8       | `pkg:github/openssl/openssl@3.5.7` |
| [CVE-2026-42770](https://nvd.nist.gov/vuln/detail/CVE-2026-42770) |       3.7       | `pkg:github/openssl/openssl@3.5.7` |
| [CVE-2026-42768](https://nvd.nist.gov/vuln/detail/CVE-2026-42768) |       3.7       | `pkg:github/openssl/openssl@3.5.7` |

## OpenVox 9.0.0-alpha1

Released May 21, 2026.

This is a **prerelease** of OpenVox 9 and is not yet the stable release. See the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/9.0.0-alpha1) for the full list of changes.
