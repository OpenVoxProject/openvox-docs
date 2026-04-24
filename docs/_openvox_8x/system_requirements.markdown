---
layout: default
title: "OpenVox system requirements"
---

OpenVox's system requirements can depend on your deployment type and size. Before installing, ensure your hardware and operating systems are compatible with the `openvox-agent` packages we publish.

> To install OpenVox, first [view the pre-install tasks](./install_pre.html).

### Hardware

The OpenVox agent service has no particular hardware requirements and can run on nearly anything.

However, the OpenVox server service is fairly resource intensive, and should be installed on a robust dedicated server.

* At a minimum, your OpenVox server should have two processor cores and at least 1 GB of RAM.
* To comfortably serve at least 1,000 nodes, it should have 2-4 processor cores and at least 4 GB of RAM.

The demands on the OpenVox server vary widely between deployments. The total needs are affected by the number of agents being served, how frequently those agents check in, how many resources are being managed on each agent, and the complexity of the manifests and modules in use.

### OpenVox agent and operating system support life cycles

In general we try, to support OpenVox agent for the operating system's life cycle. Essentially, OpenVox stops publishing packages for a platform 30 days after its end-of-life (EOL) date. For example, RHEL 7 reached its EOL on June 30, 2024. This means on or around July 23, OpenVox stopped providing fixes, updates, or support for that agent package.

### Platforms with packages

We publish and test official `openvox-agent` packages for these platforms. Less common and sometimes brand new platforms might not be automatically tested, but packages are still available for them.

| Operating system                           | Tested versions                                   |
|--------------------------------------------|---------------------------------------------------|
| Red Hat Enterprise Linux (and derivatives) | 7, 8, 9,10                                        |
| SUSE Linux Enterprise Server               | 15, 16                                            |
| Debian                                     | Wheezy (10), Jessie (11), Stretch (12), (13)      |
| Ubuntu                                     | 18.04, 20.04, 22.04, 24.04, 25.04, 26.04          |
| Fedora                                     | 36, 40,41,42,43                                   |
| Microsoft Windows (Server OS)              | 2008R2, 2012R2, 2016                              |
| Microsoft Windows (Consumer OS)            | 10 Enterprise                                     |
| macOS                                      | 10.12 Sierra, 10.13 High Sierra                   |

### Platforms without packages

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

### Prerequisites

If you install OpenVox via the official packages, you don't need to worry about prerequisites; your system's package manager handles all of them. These are only listed for those running Puppet from source or on unsupported systems.

* **Ruby:** We currently only test and package with 3.2.x versions of Ruby, therefore you should only use this version. Other interpreters and versions of Ruby are not covered by our tests.

* Mandatory libraries:

  * CFPropertyList 2.2 or later
  * [Hiera]({{hiera}}/) 3.2.1 or later
  * [Facter]({{facter}}/) 2.0 or later

* Optional libraries: The `msgpack` gem is required if you are using [msgpack serialization](./experiments_msgpack.html).
