---
layout: default
title: "OpenFact release notes"
---

This page documents the history of the OpenFact 5 series.

## OpenFact 5.7.2

Released on October 6, 2026. This is the version bundled with `openvox-agent` 8.30.0.

A failed request for the EC2 metadata root listing is treated as no metadata again. Since 5.7.1 it raised instead, so on KVM and Xen guests without an EC2-compatible metadata service every fact resolution logged an error and `facter` exited with a non-zero status.

Please check the [GitHub OpenFact release page](https://github.com/OpenVoxProject/openfact/releases/tag/5.7.2) for details on new features or bug fixes.

## OpenFact 5.7.1

Released on September 23, 2026

EC2 metadata is published only when every metadata request succeeds. A timeout or error part-way through the lookup no longer leaves a partially populated `ec2_metadata` fact in the cache.

Please check the [GitHub OpenFact release page](https://github.com/OpenVoxProject/openfact/releases/tag/5.7.1) for details on new features or bug fixes.

## OpenFact 5.7.0

Released on July 12, 2026

The `virtual` and `is_virtual` facts detect Proxmox and QEMU guests on Windows.

Please check the [GitHub OpenFact release page](https://github.com/OpenVoxProject/openfact/releases/tag/5.7.0) for details on new features or bug fixes.

## OpenFact 5.6.1

Released on May 11, 2026

Please check the [GitHub OpenFact release page](https://github.com/OpenVoxProject/openfact/releases/tag/5.6.1) for details on new features or bug fixes.

## OpenFact 5.6.0

Released on April 9, 2026

Please check the [GitHub OpenFact release page](https://github.com/OpenVoxProject/openfact/releases/tag/5.6.0) for details on new features or bug fixes.

## OpenFact 5.5.0

Released on February 20, 2026

Please check the [GitHub OpenFact release page](https://github.com/OpenVoxProject/openfact/releases/tag/5.5.0) for details on new features or bug fixes.

## OpenFact 5.4.0

Released on February 15, 2026

OpenFact accepts version 1.17 of the `ffi` gem and supports JRuby 10. On OpenBSD the processor count takes SMT into account, and OpenFact no longer runs `dhcpcd` when that daemon is not running. See the [GitHub OpenFact release page](https://github.com/OpenVoxProject/openfact/releases/tag/5.4.0).

## OpenFact 5.3.0

Released on January 6, 2026

Adds support for Ruby 4.0. The `virtual` and `is_virtual` facts detect QEMU and Yandex hypervisors, which fixes `is_virtual` on OpenBSD guests, and the Solaris processor facts are fixed. See the [GitHub OpenFact release page](https://github.com/OpenVoxProject/openfact/releases/tag/5.3.0).

## OpenFact 5.2.1

Released on December 15, 2025

Relaxes the version constraint on the `logger` gem. See the [GitHub OpenFact release page](https://github.com/OpenVoxProject/openfact/releases/tag/5.2.1).

## OpenFact 5.2.0

Released on December 4, 2025

Adds the `os.support.end` fact on Linux, read from `SUPPORT_END` in `os-release`, and reworks the `facter` man page. See the [GitHub OpenFact release page](https://github.com/OpenVoxProject/openfact/releases/tag/5.2.0).

## OpenFact 5.1.0

Released on July 10, 2025

Adds support for Ruby 3.4 and adds `/usr/local/etc/facter/facts.d` to the default external fact directories. See the [GitHub OpenFact release page](https://github.com/OpenVoxProject/openfact/releases/tag/5.1.0).

## OpenFact 5.0.0

Released on June 27, 2025

The first OpenFact release, renamed from Facter after version 4.10.0. It also detects Windows Server 2025, adds ZFS facts on Linux, and fixes the `virtual` fact on FreeBSD. See the [GitHub OpenFact release page](https://github.com/OpenVoxProject/openfact/releases/tag/5.0.0).
