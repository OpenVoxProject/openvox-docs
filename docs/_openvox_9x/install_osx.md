---
layout: default
title: "Installing OpenVox agent: macOS"
---

[agent_settings]: ./config_important_settings.html#settings-for-agents-all-nodes

These instructions cover installing `openvox-agent` on macOS systems.

1. Before installing `openvox-agent`, read the [pre-install tasks](./install_pre.html).

2. Download the current macOS package from
   <https://downloads.voxpupuli.org/mac>.

   The macOS package bundles the runtime it needs, so you do not need to install
   Ruby or other OpenVox dependencies separately.

3. Install the package.

   You can use the graphical installer or install from the command line.

## Graphical installation

1. Open the downloaded disk image.
2. Run the included installer package.
3. Follow the prompts to complete the installation.

## Command-line installation

1. Mount the disk image:

   ```bash
   sudo hdiutil mount <DMG FILE>
   ```

2. Install the package from the mounted image:

   ```bash
   sudo installer -pkg /Volumes/<IMAGE>/<PKG FILE> -target /
   ```

3. Unmount the disk image when you are done:

   ```bash
   sudo hdiutil unmount /Volumes/<IMAGE>
   ```

## After installation

1. Add `/opt/puppetlabs/bin` to your `PATH` if you want to run `puppet` and
   `facter` without the full path.

2. Configure the server name in `puppet.conf` if your server is not reachable
   as `puppet`. For commonly changed settings, see the
   [agent settings list][agent_settings].

3. Run a test agent execution if this node will talk to an OpenVox Server:

   ```bash
   sudo /opt/puppetlabs/bin/puppet agent --test
   ```

4. Sign the certificate on the CA if your deployment uses manual certificate approval.

If you are replacing legacy Puppet packages on the machine, back up `/etc/puppetlabs/`
before you begin. OpenVox continues using the same configuration paths.
