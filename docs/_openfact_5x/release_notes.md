---
layout: default
title: "OpenFact release notes"
---

This page documents the history of the OpenFact 5.5 series.

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
