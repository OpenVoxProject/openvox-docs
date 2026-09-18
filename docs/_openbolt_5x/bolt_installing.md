---
layout: default
title: Installing OpenBolt
---

# Installing OpenBolt

Packaged versions of OpenBolt are available for several Linux distributions, macOS,
and Microsoft Windows.

| Operating system          | Versions            |
| ------------------------- | ------------------- |
| Amazon Linux              | 2, 23               |
| Debian                    | 12, 13              |
| Enterprise Linux          | 8, 9, 10            |
| Fedora                    | 43, 44              |
| macOS                     | 13, 14, 15          |
| Microsoft Windows         | 11                  |
| Microsoft Windows Server* | 2019, 2022, 2025    |
| SLES                      | 15, 16              |
| Ubuntu                    | 22.04, 24.04, 26.04 |

## Install OpenBolt on Linux

### Debian/Ubuntu

Download and install the appropriate file for the OS you have

```console
source /etc/os-release
wget "https://apt.voxpupuli.org/openvox8-release-${ID}${VERSION_ID}.deb"
apt install ./openvox8-release*.deb
```

Then install OpenBolt:

```console
sudo apt-get update
sudo apt-get install openbolt
```

To upgrade OpenBolt:

```console
sudo apt-get update
sudo apt-get --only-upgrade install openbolt
```

To remove OpenBolt:

```console
sudo apt purge openbolt
```

### Enterprise Linux family

Download and install the appropriate file for the OS you have

```console
# Amazon Linux 2
sudo rpm -Uvh https://yum.voxpupuli.org/openvox8-release-amazon-2.noarch.rpm
# Amazon Linux 2023
sudo rpm -Uvh https://yum.voxpupuli.org/openvox8-release-amazon-2023.noarch.rpm
# EL8
sudo rpm -Uvh https://yum.voxpupuli.org/openvox8-release-el-8.noarch.rpm
# EL9
sudo dnf install https://yum.voxpupuli.org/openvox8-release-el-9.noarch.rpm
# EL10
sudo dnf install https://yum.voxpupuli.org/openvox8-release-el-10.noarch.rpm
# Fedora 43
sudo dnf install https://yum.voxpupuli.org/openvox8-release-fedora-43.noarch.rpm
# Fedora 44
sudo dnf install https://yum.voxpupuli.org/openvox8-release-fedora-44.noarch.rpm
# SLES 15
sudo zypper install https://yum.voxpupuli.org/openvox8-release-sles-15.noarch.rpm
# SLES 16
sudo zypper install https://yum.voxpupuli.org/openvox8-release-sles-16.noarch.rpm
```

Then install OpenBolt:

```console
# Amazon/EL/Fedora
sudo dnf install openbolt
# SLES
sudo zypper install openbolt
```

To upgrade OpenBolt:

```console
# Amazon/EL/Fedora
sudo dnf upgrade --refresh openbolt
# SLES
sudo zypper up openbolt
```

To remove OpenBolt:

```console
# Amazon/EL/Fedora
sudo dnf remove openbolt
# SLES
sudo zypper remove openbolt
```

## Install OpenBolt on macOS

Use the Apple Disk Image (DMG) to install OpenBolt on macOS:

1. Download the OpenBolt installer package for your macOS version from `https://downloads.voxpupuli.org/mac`.
2. Double-click the `openbolt-[version].dmg` file to mount the installer and
   then double-click `openbolt-[version]-installer.pkg` to run the installer.

To upgrade OpenBolt: download the DMG again and repeat the installation steps.

## Install OpenBolt on Microsoft Windows

Use the Windows installer (MSI) package to install OpenBolt on Windows:

1. Download the [more recent OpenBolt installer package](https://downloads.voxpupuli.org/windows/openvox8/).

2. Double-click the MSI file and run the installer.

To upgrade OpenBolt to the latest version, download the MSI again and repeat the
installation steps.

### Uninstall OpenBolt

You can uninstall OpenBolt from Windows **Apps & Features**:

1. Press **Windows** + **X** + **F** to open **Apps & Features**.

2. Search for **OpenBolt**, select it, and click **Uninstall**.

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
enables sharing gem content with Puppet installations — such as when running
`apply` on `localhost` — that use the same Ruby version.

To install a gem for use with OpenBolt, use the command appropriate to your
operating system:

- On Windows with the default install location:

    ```powershell
    "C:/Program Files/Puppet Labs/Bolt/bin/gem.bat" install --user-install <GEM>
    ```

- On other platforms:

    ```console
    /opt/puppetlabs/bolt/bin/gem install --user-install <GEM>
    ```
