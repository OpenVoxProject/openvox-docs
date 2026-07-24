---
layout: default
title: "OpenVox Server: Release Notes"
canonical: "/openvox-server/latest/release_notes.html"
---

## OpenVox Server 8.15.1

Released July 22, 2026.

This is a bug-fix release of OpenVox Server.

All bug fixes, new features and other changes are provided on the [project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/8.15.1).

### Known Issues in 8.15.1

#### `resolv` times out when `/etc/resolv.conf` contains multiple IPv6 nameservers

See [8.15.0 known issues](#known-issues-in-8150) for details.

## OpenVox Server 8.15.0

{% include alert.html type="note" title="Unreleased" content="Packages for version 8.15.0 were not released due to broken FIPS builds." %}

This is an enhancement, bug-fix, and security release of OpenVox Server.

All bug fixes, new features and other changes are provided on the [project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/8.15.0).

### Security Issues Resolved in 8.15.0

| Identifier                                                        | CVSS 3.1 Score | Resolved By                                                    |
| :---------------------------------------------------------------- | :------------: | :------------------------------------------------------------- |
| [CVE-2026-29062](https://nvd.nist.gov/vuln/detail/CVE-2026-29062) |       7.5      | `pkg:maven/com.fasterxml.jackson.core/jackson-core@2.21.5`     |
| [CVE-2026-54513](https://nvd.nist.gov/vuln/detail/CVE-2026-54513) |       8.1      | `pkg:maven/com.fasterxml.jackson.core/jackson-databind@2.21.5` |
| [CVE-2026-54512](https://nvd.nist.gov/vuln/detail/CVE-2026-54512) |       8.1      | `pkg:maven/com.fasterxml.jackson.core/jackson-databind@2.21.5` |
| [CVE-2026-59889](https://nvd.nist.gov/vuln/detail/CVE-2026-59889) |       6.5      | `pkg:maven/com.fasterxml.jackson.core/jackson-databind@2.21.5` |
| [CVE-2026-59888](https://nvd.nist.gov/vuln/detail/CVE-2026-59888) |       6.5      | `pkg:maven/com.fasterxml.jackson.core/jackson-databind@2.21.5` |
| [CVE-2026-54518](https://nvd.nist.gov/vuln/detail/CVE-2026-54518) |       6.5      | `pkg:maven/com.fasterxml.jackson.core/jackson-databind@2.21.5` |
| [CVE-2026-54516](https://nvd.nist.gov/vuln/detail/CVE-2026-54516) |       5.3      | `pkg:maven/com.fasterxml.jackson.core/jackson-databind@2.21.5` |
| [CVE-2026-54517](https://nvd.nist.gov/vuln/detail/CVE-2026-54517) |       5.3      | `pkg:maven/com.fasterxml.jackson.core/jackson-databind@2.21.5` |
| [CVE-2026-54514](https://nvd.nist.gov/vuln/detail/CVE-2026-54514) |       5.3      | `pkg:maven/com.fasterxml.jackson.core/jackson-databind@2.21.5` |

### Known Issues in 8.15.0

#### `resolv` times out when `/etc/resolv.conf` contains multiple IPv6 nameservers

The JRuby 9.4.15.0 upgrade included in this release updated the Ruby `resolv`
library to a newer version. This newer `resolv` version introduced a mis-match
where queries to IPv6 DNS servers are sent using compressed addresses (e.g.
`2001:db8::1`), while responses arrive from un-compressed addresses (e.g.
`2001:db8:0:0:0:0:0:1`). This mis-match means that queries to IPv6 servers
are never seen as "answered" and the library returns an empty `[]` response
after waiting for 160 seconds.

This issue only occurs when `/etc/resolv.conf` is configured exclusively with
two or more IPv6 nameservers. For example:

```console
# cat /etc/resolv.conf
# Google Public DNS (IPv6)
nameserver 2001:4860:4860::8888
nameserver 2001:4860:4860::8844
```

This issue will affect modules that use the `Resolv` library to look up
DNS records, notably: `puppet-dnsquery`.

The following command can be used to test if an OpenVox Server is affected
by the issue:

```bash
/opt/puppetlabs/bin/puppetserver ruby -rtimeout -rresolv -e 'Timeout.timeout(10) { puts Resolv::DNS.new.getaddresses("voxpupuli.org") }'
```

The command will take several seconds to run, as a JVM is launched, but should
print a list of DNS addresses to STDOUT:

```console
104.21.84.238
172.67.198.227
2606:4700:3035::ac43:c6e3
2606:4700:3035::6815:54ee
```

The command will print a `Timeout::Error` if the issue is present:

```bash
Timeout::Error: execution expired
  timeout at uri:classloader:/META-INF/jruby.home/lib/ruby/stdlib/timeout.rb:199
   <main> at -e:1
```

See [OpenVoxProject/openvox-server#535][openvox-server-535] for more details
and subscribe for updates on a fix. Recommended workaround is to downgrade the
`openvox-server` package to version 8.14.1.

[openvox-server-535]: https://github.com/OpenVoxProject/openvox-server/issues/535

## OpenVox Server 8.14.1

Released June 24, 2026.

This is a bug-fix release of OpenVox Server.

All bug fixes, new features and other changes are provided on the [project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/8.14.1).

## OpenVox Server 8.14.0

{% include alert.html type="note" title="Unreleased" content="Packages for version 8.14.0 were not released due to broken APIs for monitoring service status and performance." %}

This is an enhancement, bug-fix, and security release of OpenVox Server.

All bug fixes, new features and other changes are provided on the [project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/8.14.0).

### Security Issues Resolved in 8.14.0

| Identifier                                                        | CVSS 3.1 Score | Resolved By                                           |
| :---------------------------------------------------------------- | :------------: | :---------------------------------------------------- |
| [CVE-2026-2332](https://nvd.nist.gov/vuln/detail/CVE-2026-2332)   |       9.1      | `pkg:maven/org.eclipse.jetty/jetty-http@12.1.9`       |
| [CVE-2025-11143](https://nvd.nist.gov/vuln/detail/CVE-2025-11143) |       6.5      | `pkg:maven/org.eclipse.jetty/jetty-http@12.1.9`       |
| [CVE-2024-6763](https://nvd.nist.gov/vuln/detail/CVE-2024-6763)   |       5.3      | `pkg:maven/org.eclipse.jetty/jetty-http@12.1.9`       |
| [CVE-2026-54515](https://nvd.nist.gov/vuln/detail/CVE-2026-54515) |       5.3      | `pkg:maven/tools.jackson.core/jackson-databind@3.0.1` |
| [CVE-2026-1225](https://nvd.nist.gov/vuln/detail/CVE-2026-1225)   |       N/A      | `pkg:maven/ch.qos.logback/logback-core@1.5.32`        |

## OpenVox Server 8.13.0

Released May 4, 2026.

This is an enhancement and bug-fix release of OpenVox Server.

All bug fixes, new features and other changes are provided on the [project's GitHub release page](https://github.com/OpenVoxProject/openvox-server/releases/tag/8.13.0).

### Security Issues Resolved in 8.13.0

| Identifier                                                               | CVSS 3.1 Score | Resolved By                                                |
| :----------------------------------------------------------------------- | :------------: | :--------------------------------------------------------- |
| [GHSA-72hv-8253-57qq](https://github.com/advisories/GHSA-72hv-8253-57qq) |       N/A      | `pkg:maven/com.fasterxml.jackson.core/jackson-core@2.21.3` |

### Known Issues in 8.13.0

#### `jruby-openssl` 0.15.4 Fails to Parse EC Keys

The `openssl` JRuby library included in this release may fail to parse some PEM
files that previous versions were able to parse, resulting in errors such as:

```console
java.lang.NoSuchMethodError: 'org.bouncycastle.asn1.ASN1Primitive org.bouncycastle.asn1.sec.ECPrivateKey.getParameters()'
```

Not all files are affected, the error seems to be triggered by specific patterns in
ASN.1 content. This issue is fixed in version 8.14.1.

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
