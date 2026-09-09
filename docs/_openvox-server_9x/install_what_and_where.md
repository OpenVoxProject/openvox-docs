---
layout: default
title: "What gets installed and where (OpenVox Server)"
---

When you install the `openvox-server` package, it places files and directories in the following locations.

## Executables and binaries

| Location | Description |
| -------- | ----------- |
| `/opt/puppetlabs/bin/puppetserver` | Main `puppetserver` executable |
| `/opt/puppetlabs/bin/puppet` | Puppet CLI (installed by the `openvox-agent` dependency) |
| `/opt/puppetlabs/server/bin/` | `puppetserver` and `puppetdb` binaries — not on `PATH` by default |
| `/opt/puppetlabs/puppet/bin/` | Private Ruby runtime and agent binaries |

## Configuration files

OpenVox Server uses two configuration directories:

**Server configuration** (`/etc/puppetlabs/puppetserver/`):

| File | Description |
| ---- | ----------- |
| `conf.d/puppetserver.conf` | Main server settings |
| `conf.d/webserver.conf` | Jetty web server settings |
| `conf.d/web-routes.conf` | Web application mount points |
| `conf.d/auth.conf` | HTTPS access control rules |
| `conf.d/ca.conf` | Certificate authority service settings |
| `conf.d/global.conf` | Global settings |
| `conf.d/metrics.conf` | Metrics service settings |
| `logback.xml` | Log level and output configuration |
| `ca/` | CA certificates, CRL, signed certs, and CSRs (`cadir`) |

**Puppet configuration** (`/etc/puppetlabs/puppet/`):

| File | Description |
| ---- | ----------- |
| `puppet.conf` | Main Puppet configuration — server settings go in the `[server]` section |
| `ssl/` | Server node certificate, private key, and CRL (`ssldir`) |
| `hiera.yaml` | Hiera lookup configuration |

## Code directory

Puppet manifests and modules live under `/etc/puppetlabs/code/`. This is the
[codedir](/openvox/latest/dirs_codedir.html) used by the server when compiling catalogs.

## Runtime data

| Path | Description |
| ---- | ----------- |
| `/opt/puppetlabs/server/data/puppetserver/` | Server runtime data (reports, state, JRuby gems, yaml cache) |
| `/var/run/puppetlabs/puppetserver/` | PID file |

## Log files

| Path | Description |
| ---- | ----------- |
| `/var/log/puppetlabs/puppetserver/puppetserver.log` | Main server log |
| `/var/log/puppetlabs/puppetserver/puppetserver-access.log` | HTTP access log |
| `/var/log/puppetlabs/puppetserver/puppetserver-status.log` | Status service log |

## Service

OpenVox Server runs as the `puppetserver` service, managed by systemd.

| Property | Value |
| -------- | ----- |
| Service name | `puppetserver` |
| Runs as user | `puppet` (created by the package installer) |
| JVM heap config | `/etc/sysconfig/puppetserver` (EL) or `/etc/default/puppetserver` (Debian/Ubuntu) |

## Migrating from Puppet Server packages

OpenVox Server uses the same directory layout as Puppet Server. If you are replacing
legacy Puppet Server packages:

- Back up `/etc/puppetlabs/` and `/opt/puppetlabs/server/data/` before you begin.
- Expect the same command names, configuration paths, and service name after installation.
- Do not install Puppet Server and OpenVox Server packages side by side on the same host.
