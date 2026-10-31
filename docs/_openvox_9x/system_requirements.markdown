---
layout: default
title: "OpenVox system requirements"
---

<!-- markdownlint-disable MD013 -->

OpenVox's system requirements can depend on your deployment type and size. Before installing, ensure your hardware and operating systems are compatible with the `openvox-agent` packages we publish.

> To install OpenVox, first [view the pre-install tasks](./install_pre.html).

## Hardware

The OpenVox agent service has no particular hardware requirements and can run on nearly anything.

However, the OpenVox server service is fairly resource intensive, and should be installed on a robust dedicated server.

* At a minimum, your OpenVox server should have two processor cores and at least 1 GB of RAM.
* To comfortably serve at least 1,000 nodes, it should have 2-4 processor cores and at least 4 GB of RAM.

The demands on the OpenVox server vary widely between deployments. The total needs are affected by the number of agents being served, how frequently those agents check in, how many resources are being managed on each agent, and the complexity of the manifests and modules in use.

## OpenVox agent and operating system support life cycles

OpenVox aims to build packages for an operating system for as long as its vendor supports it. When a platform is dropped from the build list, its existing packages stay on the package servers; the [Supported platforms](supported_platforms.html) page lists those platforms and the last version built for each.

## Platforms with packages

The operating systems with official `openvox-agent`, `openvox-server`, and `openvoxdb` packages are listed on the [Supported platforms](supported_platforms.html) page. That page is generated from the build system's platform list and the package servers, and it also lists the platforms whose packages remain available but are no longer built.

## Platforms without packages

OpenVox and its prerequisites are known to run on the following platforms, but we do not provide official open source packages or perform automated testing.

* Other Linux:
  * Gentoo Linux
  * Mandriva Corporate Server 4
  * Arch Linux

* Other Unix:
  * Oracle Solaris, version 10 and higher
  * AIX, version 6.1 and higher
  * FreeBSD 4.7 and later
  * OpenBSD 4.1 and later
  * HP-UX

## Prerequisites

If you install OpenVox via the official packages, you don't need to worry about prerequisites; your system's package manager handles all of them. These are only listed for those running Puppet from source or on unsupported systems.

* **Ruby:** OpenVox 9 packages bundle and test with Ruby 4.0.x, so you should use this version. The `openvox` gem requires at least Ruby 3.2. Other interpreters and versions of Ruby are not covered by our tests.

* Mandatory libraries:

  * CFPropertyList 2.2 or later
  * [Hiera](/openvox/latest/hiera_intro.html) 3.2.1 or later
  * [Facter](/openfact/latest/) 2.0 or later

* Optional libraries: The `msgpack` gem is required if you are using [msgpack serialization](subsystem_msgpack.html).
