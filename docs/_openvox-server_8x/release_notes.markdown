---
layout: default
title: "OpenVox Server: Release Notes"
canonical: "/openvox-server/latest/release_notes.html"
---

## OpenVox Server 8.13.0

Released 2026-05-04.

This is an enhancement and bug-fix release of OpenVox Server.

All bug fixes, new features and other changes are provided on the [project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/8.13.0).

### Known Issues

#### `jruby-openssl` 0.15.4 Fails to Parse EC Keys

The `openssl` JRuby library included in this release may fail to parse some PEM
files that previous versions were able to parse, resulting in errors such as:

```console
java.lang.NoSuchMethodError: 'org.bouncycastle.asn1.ASN1Primitive org.bouncycastle.asn1.sec.ECPrivateKey.getParameters()'
```

Not all files are affected, the error seems to be triggered by specific patterns in
ASN.1 content. See [OpenVoxProject/openvox-server#322][openvox-server-322]
for more details and subscribe for updates on a fix. Recommended workaround is
to downgrade the `openvox-server` package to version 8.12.1.

[openvox-server-322]: https://github.com/OpenVoxProject/openvox-server/issues/322

## OpenVox Server 8.12.1

Released January 21, 2025.

This is a bug-fix release of OpenVox Server, addressing a performance regression introduced in 8.12.0.

All bug fixes, new features and other changes are provided on the [project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/8.12.1).

## OpenVox Server 8.12.0

Released January 21, 2025.

This is a major release of OpenVox Server. Java 11 support has been removed; Java 17 or 21 is now
required. The build system has been significantly overhauled with new platform support (Amazon Linux 2,
Fedora 42/43, RHEL FIPS variants), migration to the `org.openvoxproject` namespace on Clojars, and
numerous security dependency updates addressing CVEs in JRuby, Jetty, Jackson, Logback, and Bouncy Castle.

All bug fixes, new features and other changes are provided on the [project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/8.12.0).

## OpenVox Server 8.11.0

Released August 24, 2024.

This is a bug-fix and enhancement release of OpenVox Server.

All bug fixes, new features and other changes are provided on the [project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/8.11.0).

## OpenVox Server 8.10.0

Released July 31, 2024.

This is an enhancement release of OpenVox Server, adding Java 21 support and security dependency updates.

All bug fixes, new features and other changes are provided on the [project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/8.10.0).

## OpenVox Server 8.9.0

Released July 19, 2024.

This is the initial OpenVox Server release. It switches packaging to OpenVoxProject releases, replaces the `puppetserver-ca` gem with `openvoxserver-ca`, and removes the analytics/dropsonde integration.

All bug fixes, new features and other changes are provided on the [project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/8.9.0).
