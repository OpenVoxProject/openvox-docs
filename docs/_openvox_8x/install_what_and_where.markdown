---
layout: default
title: "What gets installed and where (agent)"
---

When you install the `openvox-agent` package, it places files and directories in the following locations. Windows paths use `%PROGRAMDATA%` which is usually `C:\ProgramData`.

## Executables and binaries

| Location | Description |
|----------|-------------|
| `/opt/puppetlabs/bin/` | Public binaries (`puppet`, `facter`). This directory is on the `PATH` by default. |
| `/opt/puppetlabs/puppet/bin/` | Private binaries and the Ruby runtime used internally by the agent. Not on the `PATH` by default. |

**Windows:** `C:\Program Files\Puppet Labs\OpenVox\bin\` and `C:\Program Files\Puppet Labs\OpenVox\puppet\bin\`

## Configuration files

The main configuration directory ([confdir](./dirs_confdir.html)) defaults to:

- **\*nix:** `/etc/puppetlabs/puppet/`
- **Windows:** `%PROGRAMDATA%\PuppetLabs\puppet\etc\`
- **Non-root users:** `~/.puppetlabs/etc/puppet/`

Key files within the confdir:

| File | Description |
|------|-------------|
| `puppet.conf` | Main configuration file |
| `ssl/` | SSL certificates, keys, and CRLs — see [SSLdir](./dirs_ssldir.html) |
| `hiera.yaml` | Hiera configuration |
| `auth.conf` | HTTPS authorization rules |

## Code and data

The code directory ([codedir](./dirs_codedir.html)) defaults to:

- **\*nix:** `/etc/puppetlabs/code/`
- **Windows:** `%PROGRAMDATA%\PuppetLabs\code\`
- **Non-root users:** `~/.puppetlabs/etc/code/`

## Cache directory

The cache directory ([vardir](./dirs_vardir.html)) stores dynamic data generated during agent runs:

- **\*nix:** `/var/opt/puppetlabs/puppet/cache/`
- **Non-root users:** `~/.puppetlabs/opt/puppet/cache/`

Notable contents:

| Path | Description |
|------|-------------|
| `state/last_run_summary.yaml` | Summary of the most recent agent run |
| `state/last_run_report.yaml` | Full report from the most recent agent run |
| `state/agent_catalog_run.lock` | Lock file present while an agent run is in progress |
| `facts.d/` | External facts directory |

## Log files

- **\*nix:** `/var/log/puppetlabs/puppet/puppet.log`
- **Windows:** `%PROGRAMDATA%\PuppetLabs\puppet\var\log\puppet.log`

## Service

The agent runs as the `puppet` service, managed by the platform's native service manager (systemd on most Linux distributions).

- **Service name:** `puppet`
- **Runs as user:** `puppet` (created by the package installer)
