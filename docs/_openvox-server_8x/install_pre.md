---
layout: default
title: "Installing OpenVox Server: Before you begin"
---

[architecture]: /openvox/latest/architecture.html

Before installing OpenVox Server:

1. Confirm your platform is supported.

   OpenVox Server is a Linux-only service. Packages are available from the OpenVox
   repositories at [apt.voxpupuli.org](https://apt.voxpupuli.org) and
   [yum.voxpupuli.org](https://yum.voxpupuli.org).

   **apt-based systems:**

   | Distribution | Versions |
   | ------------ | -------- |
   | Debian | 10, 11, 12, 13 |
   | Ubuntu | 18.04, 20.04, 22.04, 24.04, 25.04, 26.04 |

   **yum/dnf-based systems:**

   | Distribution | Versions | Architectures |
   | ------------ | -------- | ------------- |
   | EL (RHEL, AlmaLinux, Rocky Linux, CentOS) | 7 | x86_64 |
   | EL (RHEL, AlmaLinux, Rocky Linux, CentOS) | 8, 9 | x86_64, aarch64, ppc64le |
   | EL (RHEL, AlmaLinux, Rocky Linux, CentOS) | 10 | x86_64, aarch64 |
   | Amazon Linux | 2, 2023 | x86_64, aarch64 |
   | Fedora | 36, 40, 41, 42, 43 | x86_64, aarch64 |
   | SLES | 15, 16 | x86_64, aarch64 |
   | RHEL FIPS | 8, 9 | x86_64 |

   Hosts running in FIPS mode need the `redhatfips` packages; see
   [Running OpenVox in FIPS mode](/openvox/8.x/fips.html).

2. Verify your Java version.

   OpenVox Server requires Java 17 or 21. Install a supported JDK from your
   distribution's repositories before installing the OpenVox Server package. OpenVox
   Server does not bundle a JDK.

3. Plan memory allocation.

   OpenVox Server is configured to use 2 GB of RAM by default. Make sure the host
   has enough available memory. For testing on a VM, you can reduce this to 512 MB
   after installation — see the [tuning guide](./tuning_guide.html).

4. Open the required port.

   OpenVox agents connect to the server on TCP port **8140**. Make sure this port is
   reachable from all managed nodes. If you are using a firewall, open it before
   starting the service.

5. Verify DNS.

   By default, agents look for the server at the hostname `puppet`. Make sure that
   name resolves correctly on the network, or plan to set the `server` setting in
   `puppet.conf` on each agent explicitly.

6. Synchronize clocks.

   OpenVox uses SSL certificates with time-based validity. If the clocks on the
   server and agent nodes differ by more than a few minutes, certificate validation
   will fail and agents will be unable to connect. Make sure NTP or a similar time
   synchronization service is running on all nodes before deploying.

7. Install and validate OpenVox Server before rolling out agents.

   In an agent-server deployment, the server must be running and reachable before
   agents can check in. See the [architecture overview][architecture] for background
   on deployment models.

Once you have completed these checks, continue with [Install OpenVox Server](./install_from_packages.html).
