---
layout: default
title: "OpenVox Server: Release Notes"
---

> **OpenVox Server 9 is in prerelease.** This page tracks the beta builds ahead of the
> stable 9.0.0 release. Expect breaking changes between prereleases; see
> [known issues](known_issues.html) for anything discovered so far.

OpenVox Server 9 pairs with OpenVox 9 (the agent): the `openvox-server` 9.x package
depends on `openvox-agent` 9.x on the same host. For the changes on the agent side,
see the [OpenVox 9 release notes](/openvox/9.x/release_notes.html).

## OpenVox Server 9.0.0-beta5

Released August 12, 2026.

This is a **prerelease** of OpenVox Server 9 and is not yet the stable release. See the
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

This is a **prerelease** of OpenVox Server 9 and is not yet the stable release. It includes
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

This is a **prerelease** of OpenVox Server 9 and is not yet the stable release. It includes
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

This is the first **prerelease** of OpenVox Server 9 and is not yet the stable release. It
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
