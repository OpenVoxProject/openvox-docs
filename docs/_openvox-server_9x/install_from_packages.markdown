---
layout: default
title: "Install OpenVox Server"
---

[prereqs]: ./install_pre.html
[tuning]: ./tuning_guide.html
[install_linux]: /openvox/latest/install_linux.html
[openvoxdb]: /openvoxdb/latest/install_via_module.html
[downloads_page]: https://voxpupuli.org/openvox/install/

Install `openvox-server` on the host that will act as the Puppet CA and catalog
compiler for your infrastructure.

**Before you begin:** Review the [pre-install tasks][prereqs] to confirm your
platform is supported, your Java version is correct, and port 8140 is open.

1. Enable the OpenVox repository for your distribution.

   On apt-based systems, download and install the release package for your OS from
   [apt.voxpupuli.org](https://apt.voxpupuli.org). For example, on Ubuntu 22.04:

   ```bash
   wget https://apt.voxpupuli.org/openvox9-release-ubuntu22.04.deb
   sudo dpkg -i openvox9-release-ubuntu22.04.deb
   sudo apt update
   ```

   On yum/dnf-based systems, install the release package for your OS from
   [yum.voxpupuli.org](https://yum.voxpupuli.org). For example, on EL 9:

   ```bash
   sudo rpm -Uvh https://yum.voxpupuli.org/openvox9-release-el-9.noarch.rpm
   ```

   For the full list of supported distributions and release packages, see the
   [Installing OpenVox][downloads_page] page.

2. Install the package.

   On apt-based systems:

   ```bash
   sudo apt install openvox-server
   ```

   On yum/dnf-based systems:

   ```bash
   sudo yum install openvox-server
   ```

3. Start and enable the service.

   ```bash
   sudo systemctl start puppetserver
   sudo systemctl enable puppetserver
   ```

4. Verify the installation.

   ```bash
   puppetserver --version
   sudo systemctl status puppetserver
   ```

   The service should be active and you should see a version string printed.

## What to do next

- [Install OpenVox agent on Linux][install_linux] — roll out agents to managed nodes.
- [Install OpenVoxDB][openvoxdb] (optional) — enables enhanced queries and reports about your infrastructure.
- Review the [tuning guide][tuning] if you need to adjust the default 2 GB JVM heap size.
