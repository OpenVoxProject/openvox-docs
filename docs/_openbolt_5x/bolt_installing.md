---
layout: default
title: Installing OpenBolt
---

# Installing OpenBolt

OpenBolt packages are available for Linux, macOS, and Microsoft Windows. Each
package bundles its own Ruby, so you do not need to install Ruby or other
dependencies separately.

OpenBolt 5.x is built against OpenVox 8, and its packages are published in the
`openvox8` repositories and download directories alongside the OpenVox 8 agent.
On a host that runs OpenVox 9, enable the `openvox8` repository as well.
OpenBolt installs into its own directory, separate from the agent, and the
`openvox9` packages keep priority. On Debian and Ubuntu, read the note in
[Debian and Ubuntu](#debian-and-ubuntu) before you install the release package.
The next OpenBolt release is numbered 9 and is built against OpenVox 9.

If downloads from `voxpupuli.org` are slow in your region, you can install from
a public mirror instead. See [Repositories and mirrors](/openvox/latest/mirrors.html).

> **Note:** On Linux, the `openbolt` package replaces an installed `puppet-bolt`
> package. On macOS and Windows, uninstall Puppet Bolt before you install
> OpenBolt, because both products use the same installation directory.

## Supported platforms

OpenBolt is built for the same operating systems as the OpenVox 8 agent. For
the full list, including CPU architectures, see
[Supported platforms](/openvox/8.x/supported_platforms.html).

| Operating system                                              | Versions                   |
| ------------------------------------------------------------- | -------------------------- |
| Amazon Linux                                                  | 2, 2023                    |
| Debian                                                        | 11, 12, 13                 |
| Enterprise Linux (RHEL, AlmaLinux, Rocky Linux, Oracle Linux) | 8, 9, 10                   |
| Fedora                                                        | 42, 43, 44                 |
| SLES                                                          | 15, 16                     |
| Ubuntu                                                        | 22.04, 24.04, 25.04, 26.04 |
| macOS (Intel and Apple silicon)                               | 13 (Ventura) and later     |
| Microsoft Windows                                             | 64-bit (x64)               |

Packages are built and tested on these versions. They might also install on
other versions of the same operating system.

## Install OpenBolt on Linux

### Debian and Ubuntu

1. Download and install the `openvox8` release package for your OS version from
   [apt.voxpupuli.org](https://apt.voxpupuli.org). The file is named
   `openvox8-release-debian<VERSION>.deb` or
   `openvox8-release-ubuntu<VERSION>.deb`. For example, on Ubuntu 24.04:

   ```console
   wget https://apt.voxpupuli.org/openvox8-release-ubuntu24.04.deb
   sudo dpkg -i openvox8-release-ubuntu24.04.deb
   ```

   > **Note:** If the host already has the `openvox9-release` package, do not
   > install `openvox8-release`. The two packages name different keyring files
   > for the same repository, apt rejects that, and every `apt` command fails
   > until one package is removed. Add the `openvox8` component to the existing
   > source instead:
   >
   > ```console
   > sed 's/ openvox9$/ openvox8/' \
   >   /etc/apt/sources.list.d/openvox9-release.list \
   >   | sudo tee /etc/apt/sources.list.d/openvox8.list
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

1. Install the `openvox8` release package for your OS from
   [yum.voxpupuli.org](https://yum.voxpupuli.org). The file is named
   `openvox8-release-<FAMILY>-<VERSION>.noarch.rpm`, where `<FAMILY>` is `el`,
   `fedora`, `amazon`, or `sles`. For example, on Enterprise Linux 9:

   ```console
   sudo dnf install -y https://yum.voxpupuli.org/openvox8-release-el-9.noarch.rpm
   ```

2. Install OpenBolt. On Enterprise Linux, Fedora, and Amazon Linux 2023:

   ```console
   sudo dnf install openbolt
   ```

   On Amazon Linux 2, use `yum` instead of `dnf`. On SLES:

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
   brew install --cask openvoxproject/openvox/openvox8-openbolt
   ```

2. Open a new terminal window and confirm that OpenBolt runs:

   ```console
   bolt --version
   ```

To upgrade OpenBolt:

```console
brew upgrade --cask openvox8-openbolt
```

To uninstall OpenBolt:

```console
brew uninstall --cask openvox8-openbolt
```

### macOS installer (DMG)

1. Download the current disk image from
   <https://downloads.voxpupuli.org/mac/openvox8/>. Choose the `arm64` file for
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
   <https://downloads.voxpupuli.org/windows/openvox8/>.

2. Run the installer. It installs the `bolt` command and the PuppetBolt
   PowerShell module.

3. Open a new PowerShell window and confirm that OpenBolt runs:

   ```powershell
   bolt --version
   ```

   The [Bolt cmdlets](bolt_cmdlet_reference.html), such as `Get-BoltVersion`,
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

The PuppetBolt PowerShell module provides the [Bolt cmdlets](bolt_cmdlet_reference.html)
and their help topics. The OpenBolt installer puts the module in
`C:\Program Files\WindowsPowerShell\Modules\PuppetBolt`, where PowerShell loads
it automatically, so you do not install it separately. Upgrading or
uninstalling OpenBolt upgrades or removes the module with it.

If PowerShell does not recognize the cmdlets, you might need to
[add the module to PowerShell](troubleshooting.html#powershell-does-not-recognize-bolt-cmdlets)
or [change execution policy restrictions](troubleshooting.html#powershell-could-not-load-the-bolt-powershell-module).

## Install OpenBolt as a gem

To install OpenBolt reliably and with all dependencies, use one of the OpenBolt
installation packages instead of a gem. Gem installations do not include core
modules which are required for common OpenBolt actions.

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
