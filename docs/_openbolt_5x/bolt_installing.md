---
layout: default
title: Installing OpenBolt
---

# Installing OpenBolt

Packaged versions of OpenBolt are available for several Linux distributions, macOS,
and Microsoft Windows.

| Operating system          | Versions                         |
| ------------------------- | -------------------------------- |
| AmazonLinux               | 2, 2023                          |
| Debian                    | 11, 12, 13                       |
| Fedora                    | 42, 43, 44                       |
| macOS                     | 11, 12                           |
| Microsoft Windows*        | 10 Enterprise, 11                |
| Microsoft Windows Server* | 2012R2, 2019                     |
| RHEL                      | 8, 9, 10                         |
| RHEL (FIPS-mode enabled)  | 9, 10                            |
| SLES                      | 15, 16                           |
| Ubuntu                    | 20.04, 22.04, 24.04, 25.04 26.04 |

> **Note:** Windows packages are automatically tested on the versions listed
> above, but might be installable on other versions.

## Install OpenBolt on Debian

### Install OpenBolt

To install OpenBolt, run the appropriate command for the version of Debian you
have installed:

- _Debian 13_

  ```console
  wget https://apt.voxpupuli.org/openvox8-release-debian13.deb
  sudo dpkg -i openvox8-release-debian13.deb
  sudo apt-get update
  sudo apt-get install openbolt
  ```

- _Debian 12_

  ```console
  wget https://apt.voxpupuli.org/openvox8-release-debian12.deb
  sudo dpkg -i openvox8-release-debian12.deb
  sudo apt-get update
  sudo apt-get install openbolt
  ```

- _Debian 11_

  ```console
  wget https://apt.voxpupuli.org/openvox8-release-debian11.deb
  sudo dpkg -i openvox8-release-debian11.deb
  sudo apt-get update
  sudo apt-get install openbolt
  ```


### Upgrade OpenBolt

To upgrade OpenBolt to the latest version, run the following command:

```console
sudo apt-get update
sudo apt install openbolt
```

### Uninstall OpenBolt

To uninstall OpenBolt, run the following command:

```console
sudo apt remove openbolt
```

## Install OpenBolt on Fedora

### Install OpenBolt

To install OpenBolt, run the appropriate command for the version of Fedora you
have installed:

- _Fedora 44_

  ```console
  sudo rpm -Uvh https://yum.puppet.com/puppet-tools-release-fedora-44.noarch.rpm
  sudo dnf install openbolt
  ```

- _Fedora 43_

  ```console
  sudo rpm -Uvh https://yum.puppet.com/puppet-tools-release-fedora-43.noarch.rpm
  sudo dnf install openbolt
  ```

- _Fedora 42_

  ```console
  sudo rpm -Uvh https://yum.puppet.com/puppet-tools-release-fedora-42.noarch.rpm
  sudo dnf install openbolt
  ```


### Upgrade OpenBolt

To upgrade OpenBolt to the latest version, run the following command:

```console
sudo dnf upgrade openbolt
```

### Uninstall OpenBolt

To uninstall OpenBolt, run the following command:

```console
sudo dnf remove openbolt
```

## Install OpenBolt on macOS

You can install OpenBolt packages for macOS using the macOS installer.


### macOS installer (DMG)

#### Install OpenBolt

Use the Apple Disk Image (DMG) to install OpenBolt on macOS:

1. Download the OpenBolt installer package for your macOS version.

   - <https://downloads.voxpupuli.org/mac/openvox8/openbolt-5.6.0-1.macos.all.x86_64.dmg>

1. Double-click the `openbolt-[version].macos.all.x86_64.dmg` file to mount the installer and
   then double-click `openbolt-[version]-installer.pkg` to run the installer.

If you get a message that the installer "can't be opened because Apple cannot check it for malicious software:"

1. Click **** > **System Preferences** > **Security & Privacy**.
1. From the **General** tab, click the lock icon to allow changes to your security settings and enter your macOS password.
1. Look for a message that says the OpenBolt installer "was blocked from use because it is not from an identified developer" and click "Open Anyway".
1. Click the lock icon again to lock your security settings.

#### Upgrade OpenBolt

To upgrade OpenBolt to the latest version, download the DMG again and repeat the
installation steps.

#### Uninstall OpenBolt

To uninstall OpenBolt, remove Bolt's files and executable:

```console
sudo rm -rf /opt/puppetlabs/bolt /opt/puppetlabs/bin/bolt
```

## Install OpenBolt on Microsoft Windows

Use one of the supported Windows installation methods to install OpenBolt.

### Windows installer (MSI)

#### Install OpenBolt

Use the Windows installer (MSI) package to install OpenBolt on Windows:

1. Download the [OpenBolt installer
    package](https://downloads.voxpupuli.org/windows/openvox8/openbolt-5.6.0-x64.msi).

1. Double-click the MSI file and run the installer.


#### Upgrade OpenBolt

To upgrade OpenBolt to the latest version, download the MSI again and repeat the
installation steps.

#### Uninstall OpenBolt

You can uninstall OpenBolt from Windows **Apps & Features**:

1. Press **Windows** + **X** + **F** to open **Apps & Features**.

1. Search for **Puppet OpenBolt**, select it, and click **Uninstall**.


#### Install PuppetBolt

To install the PuppetBolt PowerShell module, run the following command in
PowerShell:

```powershell
Install-Module PuppetBolt
```

#### Update PuppetBolt

To update the PuppetBolt PowerShell module, run the following command in
PowerShell:

```powershell
Update-Module PuppetBolt
```

#### Uninstall PuppetBolt

To uninstall the PuppetBolt PowerShell module, run the following command in
PowerShell:

```powershell
Remove-Module PuppetBolt
```

## Install OpenBolt on RHEL

### Install OpenBolt

To install OpenBolt, run the appropriate command for the version of RHEL you
have installed:

- _RHEL 10, RockyLinux 10, AlmaLinux 10, and clones

  ```console
  sudo rpm -Uvh https://yum.voxpupuli.org/openvox10-release-el-10.noarch.rpm
  sudo dnf install openbolt
  ```

- _RHEL 9, RockyLinux 9, AlmaLinux 9, and clones

  ```console
  sudo rpm -Uvh https://yum.voxpupuli.org/openvox9-release-el-9.noarch.rpm
  sudo dnf install openbolt
  ```

- _RHEL 8, RockyLinux 8, AlmaLinux 8, and clones

  ```console
  sudo rpm -Uvh https://yum.voxpupuli.org/openvox8-release-el-8.noarch.rpm
  sudo dnf install openbolt
  ```


### Upgrade OpenBolt

To upgrade OpenBolt to the latest version, run the following command:

```console
sudo dnf update openbolt
```

### Uninstall OpenBolt

To uninstall OpenBolt, run the following command:

```console
sudo dnf remove openbolt
```

## Install OpenBolt on SLES

### Install OpenBolt

To install OpenBolt, run the appropriate command for the version of SLES you
have installed:

- _SLES 16_

  ```console
  sudo rpm -Uvh https://yum.voxpupuli.org/openvox8-release-sles-16.noarch.rpm
  sudo zypper install openbolt
  ```

- _SLES 15_

  ```console
  sudo rpm -Uvh https://yum.voxpupuli.org/openvox8-release-sles-15.noarch.rpm
  sudo zypper install openbolt
  ```


### Upgrade OpenBolt

To upgrade OpenBolt to the latest version, run the following command:

```console
sudo zypper update openbolt
```

### Uninstall OpenBolt

To uninstall OpenBolt, run the following command:

```console
sudo zypper remove openbolt
```

## Install OpenBolt on AmazonLinux

### Install OpenBolt

To install OpenBolt, run the appropriate command for the version of AmazonLinux you
have installed:

- _AmazonLinux 2023

  ```console
  sudo rpm -Uvh https://yum.voxpupuli.org/openvox8-release-amazon-2023.noarch.rpm
  sudo dnf install openbolt
  ```

- _AmazonLinux 2

  ```console
  sudo rpm -Uvh https://yum.voxpupuli.org/openvox8-release-amazon-2.noarch.rpm
  sudo dnf install openbolt
  ```

### Upgrade OpenBolt

To upgrade OpenBolt to the latest version, run the following command:

```console
sudo dnf update openbolt
```

### Uninstall OpenBolt

To uninstall OpenBolt, run the following command:

```console
sudo dnf remove openbolt
```

## Install OpenBolt on Ubuntu

### Install OpenBolt

To install OpenBolt, run the appropriate command for the version of Ubuntu you
have installed:

- _Ubuntu 26.04_

  ```console
  wget https://apt.voxpupuli.org/openvox8-release-ubuntu26.04.deb
  sudo dpkg -i openvox8-release-ubuntu26.04.deb
  sudo apt-get update
  sudo apt-get install openbolt
  ```

- _Ubuntu 25.04_

  ```console
  wget https://apt.voxpupuli.org/openvox8-release-ubuntu25.04.deb
  sudo dpkg -i openvox8-release-ubuntu25.04.deb
  sudo apt-get update
  sudo apt-get install openbolt
  ```

- _Ubuntu 24.04_

  ```console
  wget https://apt.voxpupuli.org/openvox8-release-ubuntu24.04.deb
  sudo dpkg -i openvox8-release-ubuntu24.04.deb
  sudo apt-get update
  sudo apt-get install openbolt
  ```

- _Ubuntu 22.04_

  ```console
  wget https://apt.voxpupuli.org/openvox8-release-ubuntu22.04.deb
  sudo dpkg -i openvox8-release-ubuntu22.04.deb
  sudo apt-get update
  sudo apt-get install openbolt
  ```

- _Ubuntu 20.04_

  ```console
  wget https://apt.voxpupuli.org/openvox8-release-ubuntu20.04.deb
  sudo dpkg -i openvox8-release-ubuntu20.04.deb
  sudo apt-get update
  sudo apt-get install openbolt
  ```


### Upgrade OpenBolt

To upgrade OpenBolt to the latest version, run the following command:

```console
sudo apt-get update
sudo apt install openbolt
```

### Uninstall OpenBolt

To uninstall OpenBolt, run the following command:

```console
sudo apt remove openbolt
```

## Install OpenBolt as a gem

To install OpenBolt reliably and with all dependencies, use one of the Bolt
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
    "C:/Program Files/Puppet Labs/OpenBolt/bin/gem.bat" install --user-install <GEM>
    ```

- On other platforms:

    ```console
    /opt/puppetlabs/bolt/bin/gem install --user-install <GEM>
    ```
