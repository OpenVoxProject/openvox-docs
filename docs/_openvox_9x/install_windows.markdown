---
layout: default
title: "Installing OpenVox agent: Microsoft Windows"
---

[downloads]: https://downloads.voxpupuli.org/windows

Install `openvox-agent` on Microsoft Windows nodes.

**Before you begin:** Review the [pre-install tasks](./install_pre.html). In
agent-server deployments, the server side should already be installed and reachable.

1. Download the current Windows installer from [downloads.voxpupuli.org][downloads].

2. Run the installer as an administrator.

   OpenVox replaces the legacy Puppet package on the machine and continues using
   the existing `C:\ProgramData\PuppetLabs\` configuration tree.

3. Choose a server name during installation, or set it later in `puppet.conf`.

   If your server is reachable as `puppet`, the default is usually sufficient.

4. Run an initial agent execution after installation:

   ```powershell
   & 'C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat' agent --test
   ```

5. Sign the certificate on the CA if your deployment uses manual approval.

## Graphical installation

1. Double-click the MSI package.
2. Follow the installer prompts.
3. Provide the server hostname if the wizard asks for it.
4. Complete the installation and run a test check-in.

## Automated installation

Use `msiexec` for unattended installs. This keeps the same general workflow as the
legacy Puppet Windows installer, but the package you install is `openvox-agent`.

```powershell
msiexec /qn /norestart /i openvox-agent-<VERSION>-x64.msi
```

To set the server name during install:

```powershell
msiexec /qn /norestart /i openvox-agent-<VERSION>-x64.msi PUPPET_MASTER_SERVER=puppet.example.com
```

## MSI properties

These options are available when installing from the command line.

| MSI property | Purpose |
| --- | --- |
| `INSTALLDIR` | Override the default install directory |
| `PUPPET_MASTER_SERVER` | Set the `server` value in `puppet.conf` |
| `PUPPET_CA_SERVER` | Set the `ca_server` value in `puppet.conf` |
| `PUPPET_AGENT_CERTNAME` | Set the node certificate name |
| `PUPPET_AGENT_ENVIRONMENT` | Set the environment name |
| `PUPPET_AGENT_STARTUP_MODE` | Control whether the service starts automatically |
| `PUPPET_AGENT_ACCOUNT_USER` | Run the service as a different Windows account |
| `PUPPET_AGENT_ACCOUNT_PASSWORD` | Password for the service account |
| `PUPPET_AGENT_ACCOUNT_DOMAIN` | Domain for the service account |

### `INSTALLDIR`

Overrides the default installation path.

### `PUPPET_MASTER_SERVER`

Sets the hostname the node uses to reach OpenVox Server. The default value is `puppet`.

### `PUPPET_CA_SERVER`

Sets the CA host when it differs from the main server.

### `PUPPET_AGENT_CERTNAME`

Sets the certificate name the node uses when it requests catalogs and certificates.

### `PUPPET_AGENT_ENVIRONMENT`

Sets the node environment. The default is `production`.

### `PUPPET_AGENT_STARTUP_MODE`

Controls the Windows service startup behavior:

- `Automatic`
- `Manual`
- `Disabled`

### `PUPPET_AGENT_ACCOUNT_USER`

Sets the Windows account used by the OpenVox agent service. This matters when the
service must access UNC shares or other resources that `LocalSystem` cannot use.

This property is usually combined with `PUPPET_AGENT_ACCOUNT_PASSWORD` and
`PUPPET_AGENT_ACCOUNT_DOMAIN`. For example:

```powershell
msiexec /qn /norestart /i openvox-agent-<VERSION>-x64.msi PUPPET_AGENT_ACCOUNT_DOMAIN=ExampleCorp PUPPET_AGENT_ACCOUNT_USER=bob PUPPET_AGENT_ACCOUNT_PASSWORD=password
```

### `PUPPET_AGENT_ACCOUNT_PASSWORD`

Password for the account named by `PUPPET_AGENT_ACCOUNT_USER`.

### `PUPPET_AGENT_ACCOUNT_DOMAIN`

Domain for the service account.
