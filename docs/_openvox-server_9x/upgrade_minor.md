---
layout: default
title: "Upgrading OpenVox Server"
---

Use this page for routine OpenVox Server upgrades and for in-place migrations from
legacy Puppet Server packages to OpenVox Server packages.

OpenVox Server is functionally equivalent to modern Puppet Server. A host cannot have
both Puppet Server and OpenVox Server packages installed at the same time. Back up
`/etc/puppetlabs/` and `/var/opt/puppetlabs/` before you start.

## Recommended upgrade order

In an agent-server deployment, upgrade infrastructure components in this order:

1. `openvox-server`
2. `openvoxdb`
3. `openvoxdb-termini` on server nodes
4. `openvox-agent` on managed nodes

Keeping the server ahead of the agents it serves avoids compatibility issues during
the upgrade window.

## Upgrading Linux packages

On apt-based systems:

```bash
sudo apt update
sudo apt install --only-upgrade openvox-server
```

On yum/dnf-based systems:

```bash
sudo yum update openvox-server
```

After upgrading the server, restart the service to load the new version:

```bash
sudo systemctl restart puppetserver
sudo systemctl status puppetserver
```

## Migrating from legacy Puppet Server packages

If you are replacing Puppet Server rather than upgrading an existing OpenVox
installation, enable the OpenVox repository first:

1. Enable the OpenVox repository for your platform — see [OpenVox repositories and packages](/openvox/latest/openvox_platform.html).
2. Install `openvox-server`. The package manager will replace the legacy Puppet Server package.
3. Restore `/etc/puppetlabs/` from your backup if any configuration was lost.
4. Start the service and validate.

## After the upgrade

After upgrading:

1. Confirm the service is running: `sudo systemctl status puppetserver`
2. Check the server log for errors: `sudo journalctl -u puppetserver -n 50`
3. Run a test agent check-in from a managed node: `sudo puppet agent --test`
4. Verify certificate handling and OpenVoxDB connectivity where applicable.
5. Review the [release notes](./release_notes.html) for version-specific changes.
