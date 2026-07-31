---
layout: default
title: "OpenVox repositories and packages"
---

[downloads_page]: https://voxpupuli.org/openvox/install/
[apt_repo]: https://apt.voxpupuli.org
[yum_repo]: https://yum.voxpupuli.org
[windows_downloads]: https://downloads.voxpupuli.org/windows
[mac_downloads]: https://downloads.voxpupuli.org/mac

Use the OpenVox repositories to install the package set that matches your platform.
The public install guide on Vox Pupuli is the best source for current repository
URLs and package naming conventions: [Installing OpenVox][downloads_page].

## Repository locations

OpenVox publishes packages through these channels:

- Debian and Ubuntu packages: [apt.voxpupuli.org][apt_repo]
- Red Hat family packages: [yum.voxpupuli.org][yum_repo]
- Windows downloads: [downloads.voxpupuli.org/windows][windows_downloads]
- macOS downloads: [downloads.voxpupuli.org/mac][mac_downloads]

On Linux systems, install the appropriate `openvox8-release` package for your
distribution first. That package configures the repository and its signing keys.

## Package names

The primary OpenVox packages are:

| Package | Purpose |
| --- | --- |
| `openvox-agent` | Agent nodes and standalone `puppet apply` use |
| `openvox-server` | Catalog compilation and CA services |
| `openvoxdb` | Reports, inventory, and exported resources |
| `openvoxdb-termini` | Server-side plugins for OpenVoxDB integration |
| `openbolt` | Bolt package from the same repositories |

## Basic install flow

1. Enable the repository for your platform.
2. Install the package you need.
3. If you are migrating from legacy Puppet packages, restore your backup of
   `/etc/puppetlabs/` if needed.
4. Start services and validate communication.

Example Linux package installs:

```bash
apt install openvox-agent
apt install openvox-server
apt install openvoxdb
apt install openvoxdb-termini
```

```bash
yum install openvox-agent
yum install openvox-server
yum install openvoxdb
yum install openvoxdb-termini
```

## Migrating from legacy Puppet packages

OpenVox replaces the legacy Puppet packages on a host. The configuration paths and
command names remain compatible with modern Puppet releases, so the usual migration
path is:

1. Back up `/etc/puppetlabs/`.
2. Enable the OpenVox repository.
3. Install the OpenVox package that replaces the old Puppet package.
4. Validate the node before continuing with the rest of your infrastructure.

If you need a step-by-step migration overview, start with the public
[Installing OpenVox][downloads_page] guide.
