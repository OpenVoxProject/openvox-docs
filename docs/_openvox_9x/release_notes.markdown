---
layout: default
toc_levels: 1234
title: "OpenVox 9 Release Notes"
---

This page lists the links to the changes in OpenVox 9, its patch releases, and the 9.0.0 prereleases. You can also view [known issues](known_issues.html) in this release.

OpenVox's version numbers follows the [Semantic Versioning](https://semver.org/) schema, which splits a version into three segments: Major.Minor.Patch

- Major: must increase for major backward-incompatible changes
- Minor: can increase for backward-compatible new functionality or significant bug fixes
- Patch: can increase for bug fixes

## If you're upgrading from Puppet Open Source

Puppet Open Source is no longer actively developed.

You can either upgrade to Puppet 7 and then switch to OpenVox 7 and then upgrade through OpenVox 8 to OpenVox 9, or you can upgrade to Puppet 8 and then migrate to OpenVox 8 and then to OpenVox 9.

## OpenVox 9.0.0

Released October 2, 2026.

This is the first stable release of OpenVox 9. It moves the agent to current versions of its core dependencies and removes code that was deprecated during OpenVox 8; new features are planned for OpenVox 10.
The [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/9.0.0) has the full list of changes, a component-by-component comparison with 8.29.0, and an "Upgrading from OpenVox 8" checklist to work through before you upgrade.
The [release announcement](https://voxpupuli.org/blog/2026/10/02/openvox-9-release/) summarizes the changes most likely to affect you.

OpenVox 8 stays available in the `openvox8` repositories and continues to receive high-priority and security fixes for at least six months. OpenVox 8 agents can keep running against OpenVox 9 servers while you upgrade the rest of your fleet.

### Bundled components

- Ruby 4.0.7 (OpenVox 8 bundles Ruby 3.2). Gems you installed into the agent's Ruby with `/opt/puppetlabs/puppet/bin/gem` must be installed again after the upgrade, because the gem directory moves from `lib/ruby/gems/3.2.0` to `lib/ruby/gems/4.0.0`.
- OpenSSL 3.5.9, the OpenSSL long-term-support line (OpenVox 8 bundles OpenSSL 3.0).
- [OpenFact 6.2.1](/openfact/6.x/release_notes.html) (OpenVox 8 bundles OpenFact 5).
- puppet-resource_api 2.0.1, and new major versions of the vendored `*_core` modules. The `zone_core` module is no longer vendored; Solaris zone management needs the module installed separately.
- No longer shipped: the `curl` binary, the Java keystore at `/opt/puppetlabs/puppet/ssl/puppet-cacerts` (the PEM bundle at `/opt/puppetlabs/puppet/ssl/cert.pem` remains), and the `base64` and `multi_json` gems.

### Breaking changes

- **No default server.** The [`server` setting](configuration.html#server) no longer defaults to `puppet`. An agent run that would fall back on an unset `server` fails with an error that tells you to set it. Agents that use `server_list`, DNS SRV records, or an explicit server on the command line are not affected, and `ca_server` and `report_server` satisfy the check for the CA and report services.
- **Reports are off by default.** The default of the [`reports` setting](configuration.html#reports) changed from `store` to `none`. A server that should keep writing YAML reports to `reportdir` needs `reports = store` in `puppet.conf`. Servers that set `reports` explicitly (for example `puppetdb`) are not affected.
- **Deferred values are evaluated before the catalog is applied again.** [`preprocess_deferred`](configuration.html#preprocess_deferred) defaults to `true`. Set it to `false` to keep the lazy evaluation that OpenVox 8 used by default.
- **File content that looks like a checksum is literal content.** A `content` value such as `{md5}...` no longer triggers a filebucket lookup and no longer warns.
- **Removed settings, options, and APIs.** `--configprint` and the `configprint` setting (use `puppet config print`), the `pluginsync` setting, the `hiera` indirector terminus and the `data_binding_terminus` setting, the encoding argument of `regsubst`, the legacy PAL script evaluation APIs, and the `pe_serverversion` fact.
- **The systemd service provider no longer falls back to SysVInit on Debian.** `invoke-rc.d` and init script inspection are no longer consulted to decide whether a service is enabled.
- **OpenFact 6 is required.** The `openvox` gem depends on `openfact ~> 6.0` and needs Ruby 3.2 or newer.
- **The `openvox` gem ships platform builds.** Besides the generic gem there are `universal-darwin` and `x64-mingw-ucrt` builds. The `x64-mingw32` and `x86-mingw32` platforms are dropped.

### Platforms

Packages are no longer built for Enterprise Linux 7, Amazon Linux 2, Fedora 42, Debian 11, or Ubuntu 25.04; see [Supported platforms](supported_platforms.html).
The Windows agent is now built with MSYS2 and the UCRT toolchain (the `x64-mingw-ucrt` Ruby platform), so precompiled gems such as nokogiri install on Windows nodes without build tools. Installers for 9.x are in the `openvox9` directories at [downloads.voxpupuli.org](https://downloads.voxpupuli.org/).

### Other changes

- The agent logs an error when the catalog it received was compiled for a different certname, which happens with cloned images that keep a cached catalog or with a misrouting load balancer.
- A forked agent run is killed when it outlives `runtimeout`, a `RunTimeoutError` during fact collection is no longer swallowed, and the daemon waits for its certificate in the forked child instead of blocking the daemon.
- `Puppet.features.posix?` no longer depends on the `syslog` library, which fixes `Cannot determine basic system flavour` on Ruby installations without it.
- Debian packages install `/etc/default/puppet`, which sets `PUPPET_EXTRA_OPTS` for the systemd unit.
- Help output, default configuration files, and the generated reference pages use the OpenVox name and link to this site.

### Security Issues Resolved in 9.0.0

Compared with openvox-agent 8.29.0. The prerelease entries below list the issues fixed earlier in the 9.0.0 cycle. libxml2 2.15.4 also contains security fixes that have no CVE identifiers.

| Identifier                                                        | CVSS 3.1 Score | Resolved By                        |
| :---------------------------------------------------------------- | :------------: | :--------------------------------- |
| [CVE-2026-84782](https://nvd.nist.gov/vuln/detail/CVE-2026-84782) |       8.2      | `pkg:github/openssl/openssl@3.5.9` |
| [CVE-2026-80212](https://nvd.nist.gov/vuln/detail/CVE-2026-80212) |       7.5      | `pkg:gem/resolv@0.7.2` (Ruby 4.0.7) |
| [CVE-2026-35189](https://nvd.nist.gov/vuln/detail/CVE-2026-35189) |       5.3      | `pkg:github/openssl/openssl@3.5.9` |
| [CVE-2026-75805](https://nvd.nist.gov/vuln/detail/CVE-2026-75805) |       5.3      | `pkg:github/openssl/openssl@3.5.9` |
| [CVE-2026-75806](https://nvd.nist.gov/vuln/detail/CVE-2026-75806) |       5.3      | `pkg:github/openssl/openssl@3.5.9` |
| [CVE-2026-80213](https://nvd.nist.gov/vuln/detail/CVE-2026-80213) |       4.0      | `pkg:gem/resolv@0.7.2` (Ruby 4.0.7) |
| [CVE-2026-54872](https://nvd.nist.gov/vuln/detail/CVE-2026-54872) |       3.7      | `pkg:github/openssl/openssl@3.5.9` |
| [CVE-2026-77696](https://nvd.nist.gov/vuln/detail/CVE-2026-77696) |       3.7      | `pkg:github/openssl/openssl@3.5.9` |

## OpenVox 9.0.0-rc4

Released September 29, 2026.

This was the last release candidate before 9.0.0. It updates OpenFact to 6.2.1 and puppet-runtime to 2026.09.29.1, which moves OpenSSL to 3.5.9 (the fixes are listed in the 9.0.0 security table above). See the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/9.0.0-rc4).

## OpenVox 9.0.0-rc3

Released September 25, 2026.

This release candidate fixes the packaging so that every systemd-based distribution gets the `puppet` service unit. See the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/9.0.0-rc3).

## OpenVox 9.0.0-rc2

Released September 25, 2026.

This was a release candidate for OpenVox 9. See the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/9.0.0-rc2) for the full list of changes.

Notable changes in this build:

- The `server` check introduced in 9.0.0-rc1 accepts `server_list`, DNS SRV records, and an explicit server on the command line, and `ca_server` and `report_server` satisfy it for the CA and report services. 9.0.0-rc1 accepted only the `server` setting.
- A forked agent run is killed when it outlives `runtimeout`, a `RunTimeoutError` during fact collection is no longer swallowed, and the daemon waits for its certificate in the forked child instead of blocking the daemon.
- Debian packages install `/etc/default/puppet`, and the systemd unit no longer warns about an unset variable.
- `Loading facts` is logged once per run.
- OpenFact 6.2.0 and puppet-runtime 2026.09.24.1 (Ruby 4.0.7).

## OpenVox 9.0.0-rc1

Released September 4, 2026.

This was the first release candidate for OpenVox 9. It includes breaking changes; see the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/9.0.0-rc1) for the full list of changes.

Notable breaking changes in this build:

- Running as root without a [`server` setting](configuration.html#server) is now an error instead of a deprecation warning. OpenVox 9 does not default to `server=puppet`, so set the server explicitly in `puppet.conf`.
- The systemd service provider no longer falls back to `invoke-rc.d` and init script inspection on Debian to decide whether a service is enabled.
- The `openvox` gem now ships platform-specific builds for `universal-darwin` and `x64-mingw-ucrt` alongside the generic gem. The legacy `x64-mingw32` and 32-bit `x86-mingw32` gem platforms have been dropped.

### Security Issues Resolved in 9.0.0-rc1

| Identifier                                                        | CVSS 3.1 Score | Resolved By                        |
| :---------------------------------------------------------------- | :------------: | :--------------------------------- |
| [CVE-2026-63073](https://nvd.nist.gov/vuln/detail/CVE-2026-63073) |       9.8      | `pkg:github/openssl/openssl@3.5.8` |
| [CVE-2026-75803](https://nvd.nist.gov/vuln/detail/CVE-2026-75803) |       9.1      | `pkg:github/openssl/openssl@3.5.8` |
| [CVE-2026-14456](https://nvd.nist.gov/vuln/detail/CVE-2026-14456) |       7.5      | `pkg:github/openssl/openssl@3.5.8` |
| [CVE-2026-14457](https://nvd.nist.gov/vuln/detail/CVE-2026-14457) |       7.5      | `pkg:github/openssl/openssl@3.5.8` |
| [CVE-2026-18798](https://nvd.nist.gov/vuln/detail/CVE-2026-18798) |       7.5      | `pkg:github/openssl/openssl@3.5.8` |
| [CVE-2026-54874](https://nvd.nist.gov/vuln/detail/CVE-2026-54874) |       7.5      | `pkg:github/openssl/openssl@3.5.8` |
| [CVE-2026-63072](https://nvd.nist.gov/vuln/detail/CVE-2026-63072) |       7.5      | `pkg:github/openssl/openssl@3.5.8` |
| [CVE-2026-63075](https://nvd.nist.gov/vuln/detail/CVE-2026-63075) |       7.5      | `pkg:github/openssl/openssl@3.5.8` |
| [CVE-2026-63076](https://nvd.nist.gov/vuln/detail/CVE-2026-63076) |       7.5      | `pkg:github/openssl/openssl@3.5.8` |
| [CVE-2026-63074](https://nvd.nist.gov/vuln/detail/CVE-2026-63074) |       5.9      | `pkg:github/openssl/openssl@3.5.8` |

## OpenVox 9.0.0-beta2

Released August 6, 2026.

This was a **prerelease** of OpenVox 9. It includes breaking changes; see the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/9.0.0-beta2) for the full list of changes.

Notable breaking changes in this build:

- The default for the [`reports` setting](configuration.html#reports) changed from `store` to `none`, so report processing is now opt-in.
- OpenFact 6.x is now required.
- The deprecated `hiera` indirector and the data-binding settings have been removed.
- The `zone_core` vendored module has been removed.
- Java keystores have been removed from the runtime.

## OpenVox 9.0.0-beta1

Released July 15, 2026.

This was a **prerelease** of OpenVox 9. It includes breaking changes; see the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/9.0.0-beta1) for the full list of changes.

### Security Issues Resolved in 9.0.0-beta1

| Identifier                                                        | CVSS 3.1 Score | Resolved By                     |
| :------------------------------------------------------------------ | :------------: | :--------------------------------- |
| [CVE-2026-54906](https://nvd.nist.gov/vuln/detail/CVE-2026-54906) |       9.8       | `pkg:gem/concurrent-ruby@1.3.7` |
| [CVE-2026-54904](https://nvd.nist.gov/vuln/detail/CVE-2026-54904) |       7.5       | `pkg:gem/concurrent-ruby@1.3.7` |
| [CVE-2026-54905](https://nvd.nist.gov/vuln/detail/CVE-2026-54905) |       5.5       | `pkg:gem/concurrent-ruby@1.3.7` |

## OpenVox 9.0.0-alpha2

Released June 10, 2026.

This was a **prerelease** of OpenVox 9. It includes breaking changes; see the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/9.0.0-alpha2) for the full list of changes.

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

This was a **prerelease** of OpenVox 9. See the [project's github release page](https://github.com/OpenVoxProject/openvox/releases/tag/9.0.0-alpha1) for the full list of changes.
