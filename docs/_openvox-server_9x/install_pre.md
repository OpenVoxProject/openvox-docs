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
   | Debian | 13 |
   | Ubuntu | 22.04, 24.04, 26.04 |

   **yum/dnf-based systems:**

   | Distribution | Versions | Architectures |
   | ------------ | -------- | ------------- |
   | EL (RHEL, AlmaLinux, Rocky Linux, CentOS) | 8, 9, 10 | x86_64, aarch64 |
   | Amazon Linux | 2023 | x86_64, aarch64 |
   | Fedora | 43, 44 | x86_64, aarch64 |
   | SLES | 15 | x86_64 |
   | SLES | 16 | x86_64, aarch64 |
   | RHEL FIPS | 8, 9 | x86_64 |

   OpenVox Server 9 no longer ships packages for Debian 11 and 12 (they only provide
   Java 17) or for Amazon Linux 2. For the list the build system works from, see
   [Supported platforms](/openvox/latest/supported_platforms.html).

2. Verify your Java version.

   OpenVox Server 9 requires Java 21 or 25; Java 17 is no longer supported. Install a
   supported JDK from your distribution's repositories before installing the OpenVox
   Server package. OpenVox Server does not bundle a JDK.

   The `openvox-server` 9.x package depends on `openvox-agent` 9.x, so the package
   manager installs or upgrades the agent on the server host along with it.

3. Plan memory allocation.

   OpenVox Server is configured to use 2 GB of RAM by default. Make sure the host
   has enough available memory. For testing on a VM, you can reduce this to 512 MB
   after installation — see the [tuning guide](./tuning_guide.html).

4. Open the required port.

   OpenVox agents connect to the server on TCP port **8140**. Make sure this port is
   reachable from all managed nodes. If you are using a firewall, open it before
   starting the service.

5. Verify DNS.

   Starting in OpenVox 9, agents no longer fall back to the hostname `puppet` by
   default, so plan to set the `server` setting in `puppet.conf` on each agent
   explicitly. Forward and reverse DNS should be correct for the server and every
   node.

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
