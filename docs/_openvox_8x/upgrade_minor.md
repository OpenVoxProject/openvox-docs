---
layout: default
title: "Upgrading OpenVox 8"
---

Use this page for routine OpenVox 8 upgrades and for in-place migrations from the
legacy Puppet packages to OpenVox packages.

OpenVox 8 is functionally equivalent to modern Puppet in day-to-day operation. The
main migration rule is that a host cannot have both Puppet and OpenVox packages
installed at the same time. Back up `/etc/puppetlabs/` before you start.

If you are coming from Puppet 7 or OpenVox 7, read
[Upgrading from Puppet 7 to OpenVox 8](upgrade_major.html) first. OpenVox 8 changes
defaults that can break code that works on 7.

## Recommended order

Upgrade in this order:

1. `openvox-server`
2. `openvoxdb`
3. `openvoxdb-termini` on server nodes
4. `openvox-agent` on managed nodes

This keeps the central services ahead of the agents they serve.

## Upgrading Linux packages

On apt-based systems:

```bash
sudo apt update
sudo apt install --only-upgrade openvox-server openvoxdb openvoxdb-termini openvox-agent
```

On yum-based systems:

```bash
sudo yum update openvox-server openvoxdb openvoxdb-termini openvox-agent
```

If you are migrating from Puppet packages rather than upgrading an existing OpenVox
install, enable the OpenVox repository first and then install the corresponding
`openvox*` packages. The package manager will replace the legacy Puppet packages.

## Upgrading Windows and macOS agents

On Windows and macOS, download the current `openvox-agent` installer for your
platform and run it again. OpenVox continues using the same configuration paths, so
you normally do not need to move configuration files by hand.

- [Install OpenVox agent on Windows](./install_windows.html)
- [Install OpenVox agent on macOS](./install_osx.html)

## After the upgrade

After each stage:

1. Confirm services are running.
2. Run a test agent execution.
3. Check certificate handling and OpenVoxDB connectivity where applicable.
4. Review the [release notes](./release_notes.html) for version-specific changes.

## Historical Puppet documentation

For older Puppet documentation, see the Puppet docs archive:

- <https://github.com/puppetlabs/docs-archive>
