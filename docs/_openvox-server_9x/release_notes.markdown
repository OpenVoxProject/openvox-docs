---
layout: default
title: "OpenVox Server: Release Notes"
---

OpenVox Server 9 pairs with OpenVox 9 (the agent): the `openvox-server` 9.x package
depends on `openvox-agent` 9.x on the same host. For the changes on the agent side,
see the [OpenVox 9 release notes](/openvox/9.x/release_notes.html).

## OpenVox Server 9.0.1

Released October 2, 2026.

This is the first stable release of OpenVox Server 9. There is no 9.0.0 release: that
version number was taken by an artifact published to Clojars by mistake during the beta
(see 9.0.0-beta4 below), so the series starts at 9.0.1. See the
[project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/9.0.1)
for the full list of changes and the
[OpenVox 9 release notes](/openvox/9.x/release_notes.html) for the agent-side changes,
including the "Upgrading from OpenVox 8" checklist linked from there.

Breaking changes compared with OpenVox Server 8:

- **Java 21 or 25 is required.** The package depends on a Java 25 or Java 21 runtime
  package and prefers Java 25 wherever the platform provides it; Enterprise Linux 8
  provides Java 21 only. The FIPS packages run on Java 21 only, because the Bouncy
  Castle FIPS libraries are certified up to Java 21. Java 17 is no longer supported.
- **The systemd unit runs the JVM directly.** It starts
  `/opt/puppetlabs/server/apps/puppetserver/bin/java`, a launcher that runs the first
  installed Java from the supported list (25, then 21). The unit is `Type=notify`, so
  systemd reports the service as started only once OpenVox Server is up; on systemd 253
  or newer (Debian 13, Ubuntu 24.04 and 26.04, EL 10, Fedora, SLES 16) it is
  `Type=notify-reload`, while EL 8, EL 9, Amazon Linux 2023, SLES 15, Ubuntu 22.04, and
  the FIPS packages keep the `puppetserver reload` subcommand behind `ExecReload`.
  `systemctl reload puppetserver` works everywhere. The `puppetserver start` and
  `puppetserver stop` subcommands are removed; use `systemctl`. `puppetserver foreground`
  remains.
- **`JAVA_BIN` in the defaults file is optional.** The shipped
  `/etc/sysconfig/puppetserver` and `/etc/default/puppetserver` no longer set it, and a
  `JAVA_BIN="/usr/bin/java"` line left over from an 8.x install is ignored. Any other
  value is used as it is without validation, so it must point at Java 21 or 25, or at
  Java 21 for a FIPS package. `JAVA_ARGS`,
  `JAVA_ARGS_CLI`, and `TK_ARGS` work as before. The unit adds the `--add-opens` and
  `--enable-native-access` options the JVM needs through `JAVA_ARGS_DIST`, and
  `-Djruby.logger.class=...Slf4jLogger` is no longer part of the default `JAVA_ARGS`.
- **JRuby 10.1.** Server-side Ruby code (functions, report processors, custom types and
  providers used during compilation, and gems installed with `puppetserver gem`) runs on
  JRuby 10.1, which targets Ruby 4.0.
- **Filebucket reads require an administrative certificate.** The default
  [`auth.conf`](./config_file_auth.html) allows `GET` and `POST` on
  `/puppet/v3/file_bucket_file` only to certificates with the `pp_cli_auth` extension.
  Agents keep `HEAD` and `PUT`, which is all they need to store backups. The package
  manager keeps a modified `auth.conf` and drops the new default next to it as
  `auth.conf.rpmnew` or `auth.conf.dpkg-dist`; merge it to pick up this rule and the
  environment-cache rule below.
- **The embedded web server is Jetty 12**, and the `gettext` gem is no longer vendored
  with the JRuby gems.
- **The package requires `openvox-agent` 9.0.0 or newer** on the same host.
- **The `pe_serverversion` fact is removed.**
- **Reports are off by default**, because the agent's `reports` setting now defaults to
  `none`. Set `reports = store` on the server if you rely on YAML reports in `reportdir`.
- **Platforms.** Packages are no longer built for Debian 11, Debian 12, Ubuntu 25.04,
  Amazon Linux 2, or Fedora 42; see
  [Supported platforms](/openvox/9.x/supported_platforms.html).

Other notable changes:

- The server can clear its own environment cache after a code deployment: the default
  `auth.conf` allows `DELETE /puppet-admin-api/v1/environment-cache` for certificates with
  the `pp_cli_auth` extension, which the server's own certificate carries. An r10k or g10k
  post-deploy hook can call the API with the server's certificate.
- Requests that include the system trust store, such as report processors posting to
  external HTTPS endpoints, fall back to the PEM bundle at
  `/opt/puppetlabs/puppet/ssl/cert.pem`, because the OpenVox 9 agent runtime no longer
  ships a Java keystore.
- `puppetserver gem`, `puppetserver ruby`, and `puppetserver irb` use JRuby's standard
  error logger instead of printing debug logging, and `puppetserver gem list` works on
  Java 21 and newer.
- The uberjar no longer contains JRuby's Windows binaries and rdoc, which makes it smaller.

### Security issues resolved in 9.0.1

Compared with OpenVox Server 8.16.0. The Bouncy Castle scores are CVSS 4.0 base scores
from NVD; the project's release page lists them as not yet scored.

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

## OpenVox Server 9.0.0-rc2

Released September 29, 2026.

This was the last release candidate before 9.0.1. See the
[project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/9.0.0-rc2)
for the full list of changes.

Notable changes in this build:

- Packages are built with EZbake 4.2.0. The systemd unit starts the JVM through the
  `bin/java` launcher described in the 9.0.1 entry, which runs the first installed Java
  from the supported list and honors `JAVA_BIN` from the defaults file when it points at
  a supported version. This replaces the 9.0.0-rc1 behavior of running the Java binary
  chosen at package build time.
- The default `auth.conf` lets the server's own certificate clear the environment cache
  through `DELETE /puppet-admin-api/v1/environment-cache`.
- JRuby 10.1.2.0, Bouncy Castle 1.86, Jackson 2.21.7, and logback 1.6.4.

## OpenVox Server 9.0.0-rc1

Released September 9, 2026.

This was the first **release candidate** of OpenVox Server 9. See the
[project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/9.0.0-rc1)
for the full list of changes.

Notable breaking changes in this build:

- Packages are now built with EZbake 4.1.0. The systemd unit starts the JVM directly
  instead of going through a wrapper script, and the `puppetserver start` and
  `puppetserver stop` subcommands are removed. Use `systemctl start puppetserver` and
  `systemctl stop puppetserver` instead. `systemctl reload puppetserver` keeps working on
  every platform: on systemd 253 or newer the unit uses `Type=notify-reload`, while EL 8,
  EL 9, Amazon Linux 2023, SLES 15, and Ubuntu 22.04 keep the `puppetserver reload`
  subcommand behind it.
- The package now requires `openvox-agent` 9.0.0-rc1 or later.

Other notable changes:

- The default Java arguments add `--enable-native-access=ALL-UNNAMED` on Java 21 and
  later, which removes the restricted-method warnings from the service log and from
  `puppetserver gem list`.
- `puppetserver gem`, `puppetserver ruby`, and `puppetserver irb` no longer print JRuby
  debug logging; they use JRuby's standard error logger again.
- The service-readiness notification to Trapperkeeper introduced in 9.0.0-beta1 is
  reverted.

## OpenVox Server 9.0.0-beta5

Released August 12, 2026.

This was a **prerelease** of OpenVox Server 9. See the
[project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/9.0.0-beta5)
for the full list of changes.

Notable changes in this build:

- Requests that include the system trust store (for example, report processors posting to
  external HTTPS endpoints) fall back to the PEM CA bundle shipped with the OpenVox 9
  agent. The 9.x agent runtime no longer ships the Java keystore the earlier betas relied
  on, which caused `PKIX path building failed` errors when connecting to publicly signed
  endpoints.

## OpenVox Server 9.0.0-beta4

Released August 6, 2026.

This build republishes the 9.0.0-beta3 changes. The 9.0.0-beta3 packages were never
published because of a CI problem, and a `9.0.0` artifact containing the beta3 changes
was published to Clojars by mistake. See the
[project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/9.0.0-beta4).

## OpenVox Server 9.0.0-beta3

Released August 6, 2026. Packages for this build were not published; use 9.0.0-beta4.

This was a **prerelease** of OpenVox Server 9. It includes
breaking changes; see the
[project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/9.0.0-beta3)
for the full list of changes.

Notable breaking changes in this build:

- Reading content back out of the filebucket (`GET` and `POST` on
  `/puppet/v3/file_bucket_file`) now requires a client certificate with the
  `pp_cli_auth: "true"` extension in the default [`auth.conf`](./config_file_auth.html).
  Agents keep `HEAD` and `PUT`, which is all they need to store backups.
- The `gettext` gem is no longer vendored with the JRuby gems.
- The package now requires `openvox-agent` 9.0.0-beta2 or later.

## OpenVox Server 9.0.0-beta2

Released July 27, 2026.

This was a **prerelease** of OpenVox Server 9. It includes
breaking changes; see the
[project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/9.0.0-beta2)
for the full list of changes.

Notable changes in this build:

- The package now depends on `openvox-agent` 9.0.0-beta1 or later.
- JRuby is upgraded to 10.1.1.0, which targets Ruby 4.0 compatibility (the previous 10.0.x
  targeted Ruby 3.4).
- `gem install` works again during FIPS builds.
- Fixed the `resolv` regression when querying IPv6 DNS servers.

## OpenVox Server 9.0.0-beta1

Released July 15, 2026.

This was the first **prerelease** of OpenVox Server 9. It
includes breaking changes; see the
[project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/9.0.0-beta1)
for the full list of changes.

Notable breaking changes in this build:

- Java 21 or 25 is required. Java 17 is no longer supported.
- The embedded web server is upgraded to Jetty 12.
- JRuby is upgraded to the 10.x series.
- The `pe_serverversion` fact is removed.
- Packages are no longer built for Debian 11, Debian 12, or Amazon Linux 2.

Other notable changes:

- Fixed the Jolokia 2.x configuration for the [v2 metrics API](./metrics-api/v2/metrics_api.html).
- OpenVox Server now reports service readiness to Trapperkeeper.
