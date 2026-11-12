---
layout: default
title: Installing OpenBolt
---

# Installing OpenBolt

OpenBolt packages are available for Linux, macOS, and Microsoft Windows. Each
package bundles its own Ruby, so you do not need to install Ruby or other
dependencies separately.

OpenBolt 9.x is built against OpenVox 9, and its packages are published in the
`openvox9` repositories and download directories alongside the OpenVox 9 agent.
OpenBolt installs into its own directory, separate from the agent.

If downloads from `voxpupuli.org` are slow in your region, you can install from
a public mirror instead. See [Repositories and mirrors](/openvox/latest/mirrors.html).

> **Note:** On Linux, the `openbolt` package replaces an installed `puppet-bolt`
> package. On macOS and Windows, uninstall Puppet Bolt before you install
> OpenBolt, because both products use the same installation directory.

## Supported platforms

OpenBolt is built for the same operating systems as the OpenVox 9 agent. For
the full list, including CPU architectures, see
[Supported platforms](/openvox/latest/supported_platforms.html).

| Operating system                                              | Versions                   |
| ------------------------------------------------------------- | -------------------------- |
| Amazon Linux                                                  | 2023                       |
| Debian                                                        | 12, 13                     |
| Enterprise Linux (RHEL, AlmaLinux, Rocky Linux, Oracle Linux) | 8, 9, 10                   |
| Fedora                                                        | 43, 44, 45                 |
| SLES                                                          | 15, 16                     |
| Ubuntu                                                        | 22.04, 24.04, 26.04        |
| macOS (Intel and Apple silicon)                               | 13 (Ventura) and later     |
| Microsoft Windows                                             | 64-bit (x64)               |

Packages are built and tested on these versions. They might also install on
other versions of the same operating system.

## Install OpenBolt on Linux

### Debian and Ubuntu

1. Download and install the `openvox9` release package for your OS version from
   [apt.voxpupuli.org](https://apt.voxpupuli.org). The file is named
   `openvox9-release-debian<VERSION>.deb` or
   `openvox9-release-ubuntu<VERSION>.deb`. For example, on Ubuntu 24.04:

   ```console
   wget https://apt.voxpupuli.org/openvox9-release-ubuntu24.04.deb
   sudo dpkg -i openvox9-release-ubuntu24.04.deb
   ```

   If the host already has the `openvox9-release` package, for example because
   it runs the OpenVox 9 agent, skip this step.

   > **Note:** If the host has the `openvox8-release` package, for example
   > because it runs the OpenVox 8 agent, do not install `openvox9-release`.
   > The two release packages cannot currently be installed together on Debian
   > and Ubuntu. Add the `openvox9` component to the existing source instead,
   > and hold the agent package so that `apt upgrade` does not move it to
   > OpenVox 9:
   >
   > ```console
   > sed 's/ openvox8$/ openvox9/' \
   >   /etc/apt/sources.list.d/openvox8-release.list \
   >   | sudo tee /etc/apt/sources.list.d/openvox9.list
   > sudo apt-mark hold openvox-agent
   > ```

2. Install OpenBolt:

   ```console
   sudo apt update
   sudo apt install openbolt
   ```

3. Confirm that OpenBolt runs:

   ```console
   /opt/puppetlabs/bin/bolt --version
   ```

   Add `/opt/puppetlabs/bin` to your `PATH` to run `bolt` without the full path.

To upgrade OpenBolt:

```console
sudo apt update
sudo apt install --only-upgrade openbolt
```

To uninstall OpenBolt:

```console
sudo apt remove openbolt
```

### Enterprise Linux, Fedora, Amazon Linux, and SLES

1. Install the `openvox9` release package for your OS from
   [yum.voxpupuli.org](https://yum.voxpupuli.org). The file is named
   `openvox9-release-<FAMILY>-<VERSION>.noarch.rpm`, where `<FAMILY>` is `el`,
   `fedora`, `amazon`, or `sles`. For example, on Enterprise Linux 9:

   ```console
   sudo dnf install https://yum.voxpupuli.org/openvox9-release-el-9.noarch.rpm
   ```

   On SLES, `zypper` refuses the package because its signing key is not
   installed yet, so use `rpm`:

   ```console
   sudo rpm -Uvh https://yum.voxpupuli.org/openvox9-release-sles-16.noarch.rpm
   ```

   > **Note:** The `openvox9` repository also provides the OpenVox 9 agent. On
   > a host that runs the OpenVox 8 agent, a package upgrade then moves the
   > agent to OpenVox 9. To keep OpenVox 8 with `dnf`, limit the repository to
   > OpenBolt by adding this line to the `[openvox9]` section of
   > `/etc/yum.repos.d/openvox9-release.repo`:
   >
   > ```ini
   > includepkgs=openbolt
   > ```

2. Install OpenBolt. On Enterprise Linux, Fedora, and Amazon Linux:

   ```console
   sudo dnf install openbolt
   ```

   On SLES:

   ```console
   sudo zypper install openbolt
   ```

3. Confirm that OpenBolt runs:

   ```console
   /opt/puppetlabs/bin/bolt --version
   ```

   Add `/opt/puppetlabs/bin` to your `PATH` to run `bolt` without the full path.

To upgrade OpenBolt, run `sudo dnf upgrade openbolt` or `sudo zypper update openbolt`.

To uninstall OpenBolt, run `sudo dnf remove openbolt` or `sudo zypper remove openbolt`.

## Install OpenBolt on macOS

You can install OpenBolt on macOS with Homebrew or with the macOS installer
package. Both methods install the same package, and both support Intel and
Apple silicon Macs.

### Homebrew

To install OpenBolt from the [OpenVox Homebrew tap](https://github.com/OpenVoxProject/homebrew-openvox),
you must have the [Homebrew package manager](https://brew.sh/) installed.

1. Install OpenBolt:

   ```console
   brew install --cask openvoxproject/openvox/openvox9-openbolt
   ```

2. Open a new terminal window and confirm that OpenBolt runs:

   ```console
   bolt --version
   ```

To upgrade OpenBolt:

```console
brew upgrade --cask openvox9-openbolt
```

OpenBolt 5 was published as the `openvox8-openbolt` cask. The two casks
conflict, so Homebrew can't upgrade from one to the other and refuses to
install `openvox9-openbolt` while `openvox8-openbolt` is installed. To move
from OpenBolt 5 to OpenBolt 9, uninstall the old cask and install the new one:

```console
brew uninstall --cask openvox8-openbolt
brew install --cask openvoxproject/openvox/openvox9-openbolt
```

To uninstall OpenBolt:

```console
brew uninstall --cask openvox9-openbolt
```

### macOS installer (DMG)

1. Download the current disk image from
   <https://downloads.voxpupuli.org/mac/openvox9/>. Choose the `arm64` file for
   Apple silicon or the `x86_64` file for Intel.

2. Open the disk image and run `openbolt-<VERSION>-installer.pkg`. The package
   is signed and notarized, so macOS opens it without any security prompts.

3. Open a new terminal window and confirm that OpenBolt runs:

   ```console
   bolt --version
   ```

To upgrade OpenBolt, download the current disk image and run the installer
again.

To uninstall OpenBolt, remove its files and forget the package receipt:

```console
sudo rm -rf /opt/puppetlabs/bolt /opt/puppetlabs/bin/bolt
sudo pkgutil --forget org.voxpupuli.openbolt
```

> **Warning:** The **Uninstall OpenBolt** app on the disk image deletes the
> whole `/opt/puppetlabs/bin` directory, which also holds the OpenVox agent's
> `puppet` and `facter` commands. Do not use it on a Mac that runs the agent.

## Install OpenBolt on Microsoft Windows

1. Download the current installer from
   <https://downloads.voxpupuli.org/windows/openvox9/>.

2. Run the installer. It installs the `bolt` command and the PuppetBolt
   PowerShell module.

3. Open a new PowerShell window and confirm that OpenBolt runs:

   ```powershell
   bolt --version
   ```

   The [OpenBolt cmdlets](bolt_cmdlet_reference.html), such as `Get-BoltVersion`,
   are available in the same window. If PowerShell does not recognize them, see
   [PuppetBolt PowerShell module](#puppetbolt-powershell-module).

For an unattended installation, run the installer with `msiexec`:

```console
msiexec /qn /norestart /i openbolt-<VERSION>-x64.msi
```

To upgrade OpenBolt, download the current installer and run it again.

To uninstall OpenBolt, open **Settings** > **Apps** > **Installed apps**,
search for **OpenBolt**, and select **Uninstall**.

### PuppetBolt PowerShell module

The PuppetBolt PowerShell module provides the [OpenBolt cmdlets](bolt_cmdlet_reference.html)
and their help topics. The OpenBolt installer puts the module in
`C:\Program Files\WindowsPowerShell\Modules\PuppetBolt`, where PowerShell loads
it automatically, so you do not install it separately. Upgrading or
uninstalling OpenBolt upgrades or removes the module with it.

If PowerShell does not recognize the cmdlets, you might need to
[add the module to PowerShell](troubleshooting.html#powershell-does-not-recognize-openbolt-cmdlets)
or [change execution policy restrictions](troubleshooting.html#powershell-could-not-load-the-openbolt-powershell-module).

## Install OpenBolt as a gem

To install OpenBolt reliably and with all dependencies, use one of the OpenBolt
installation packages instead of a gem. Gem installations do not include core
modules which are required for common OpenBolt actions. The gem requires Ruby 3.4
or later.

To install OpenBolt as a gem:

```console
gem install openbolt
```

## Install gems in OpenBolt's Ruby environment

OpenBolt packages include their own copy of Ruby.

When you install gems for use with OpenBolt, use the `--user-install` command-line
option to avoid requiring privileged access for installation. This option also
enables sharing gem content with OpenVox installations that use the same Ruby
version, such as when running `apply` on `localhost`.

To install a gem for use with OpenBolt, use the command appropriate to your
operating system:

- On Windows with the default install location:

  ```console
  "C:/Program Files/Puppet Labs/Bolt/bin/gem.bat" install --user-install <GEM>
  ```

- On other platforms:

  ```console
  /opt/puppetlabs/bolt/bin/gem install --user-install <GEM>
  ```
