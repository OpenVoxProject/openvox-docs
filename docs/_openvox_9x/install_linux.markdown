---
layout: default
title: "Installing OpenVox agent: Linux"
---

[agent_settings]: ./config_important_settings.html#settings-for-agents-all-nodes

Install `openvox-agent` on Linux nodes that will run the OpenVox agent service or
use `puppet apply`.

**Before you begin:** Review the [pre-install tasks](./install_pre.html). If this
node will connect to an OpenVox Server, make sure the server side is already installed
and reachable.

1. Enable the OpenVox repository for your distribution.

   On apt-based systems, download and install the release package for your OS from
   [apt.voxpupuli.org](https://apt.voxpupuli.org). For example, on Ubuntu 22.04:

   ```bash
   wget https://apt.voxpupuli.org/openvox8-release-ubuntu22.04.deb
   sudo dpkg -i openvox8-release-ubuntu22.04.deb
   sudo apt update
   ```

   On yum/dnf-based systems, install the release package for your OS from
   [yum.voxpupuli.org](https://yum.voxpupuli.org). For example, on EL 9:

   ```bash
   sudo rpm -Uvh https://yum.voxpupuli.org/openvox8-release-el-9.noarch.rpm
   ```

   For other distributions and versions, see the full list of release packages on
   the respective repository pages or the [Installing OpenVox](https://voxpupuli.org/openvox/install/) page.

2. Install the package.

   On apt-based systems:

   ```bash
   sudo apt update
   sudo apt install openvox-agent
   ```

   On yum-based systems:

   ```bash
   sudo yum install openvox-agent
   ```

3. Confirm that you can run the OpenVox executables.

   The public binaries are installed under `/opt/puppetlabs/bin`. Add that directory
   to your `PATH` for interactive use, or call the binaries with their full path.

   ```bash
   export PATH=/opt/puppetlabs/bin:$PATH
   ```

4. Configure agent settings if needed.

   If the server is not reachable as `puppet`, set the `server` value in
   `puppet.conf`. For other commonly adjusted settings, see the
   [agent settings list][agent_settings].

5. Start and enable the agent service.

   ```bash
   sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true
   ```

6. Run a test check-in.

   ```bash
   sudo /opt/puppetlabs/bin/puppet agent --test
   ```

7. Sign the node certificate on the CA, if your deployment requires manual signing.

   ```bash
   sudo /opt/puppetlabs/bin/puppetserver ca list
   sudo /opt/puppetlabs/bin/puppetserver ca sign --certname <NAME>
   ```

If you are replacing Puppet packages on an existing host, back up `/etc/puppetlabs/`
before you begin. OpenVox continues to use that configuration tree after installation.

## What's next?

You now have a running server and at least one enrolled agent. The next step is to set up
a control repository so you can manage Puppet code across your infrastructure. See the
[Getting started guide](./getting_started.html) for a walkthrough of control repo setup
with r10k and writing your first Puppet code.
