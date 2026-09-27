---
layout: default
title: "Installing OpenVox agent: macOS"
---

[agent_settings]: ./config_important_settings.html#settings-for-agents-all-nodes

These instructions cover installing `openvox-agent` on macOS systems.

1. Before installing `openvox-agent`, read the [pre-install tasks](./install_pre.html).

2. Download the current macOS package from
   <https://downloads.voxpupuli.org/mac/openvox9/>.

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

5. [Allow Full Disk Access](#allow-full-disk-access) so the agent can manage
   all resources on this Mac.

If you are replacing legacy Puppet packages on the machine, back up `/etc/puppetlabs/`
before you begin. OpenVox continues using the same configuration paths.

## Allow Full Disk Access

OpenVox needs Full Disk Access to manage macOS reliably. Without it, macOS
blocks some changes the agent makes, for example deleting users with the `user`
resource or editing crontabs with the `cron` resource. A blocked change fails
with an error like this:

```text
Error: Execution of '/usr/bin/dscl . -delete /Users/example' returned 40:
  <main> delete status: eDSPermissionError
<dscl_cmd> DS Error: -14120 (eDSPermissionError)
```

When the agent runs as a service or from cron, macOS does not ask for
permission, and the change fails. When you run the agent from a terminal,
macOS asks on behalf of the terminal app, and allowing it covers only that one
change.

To allow Full Disk Access, add the Ruby interpreter bundled with the agent:

1. Open **System Settings**, and go to **Privacy & Security** > **Full Disk Access**.
2. Click **+**, press **Command-Shift-G**, enter `/opt/puppetlabs/puppet/bin/ruby`,
   and click **Open**.
3. Make sure the switch next to **ruby** is on.

Add the Ruby interpreter, not the `puppet` command. The commands in
`/opt/puppetlabs/bin` are wrapper scripts, and macOS checks the Ruby process
they start. This gives Full Disk Access to everything that runs under the
bundled Ruby, including Facter, custom facts, and custom types and providers.

macOS has no command-line way to grant Full Disk Access. On a Mac without a
local display, such as a cloud instance, connect with Screen Sharing to follow
the steps above. To grant it across many Macs, use a Privacy Preferences Policy
Control (PPPC) configuration profile from your MDM server.
