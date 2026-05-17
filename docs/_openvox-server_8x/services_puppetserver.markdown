---
layout: default
title: "OpenVox Server: Services overview"
---

[external_ca]: ./intermediate_ca.html

OpenVox is configured in an agent-server architecture, in which a primary server manages configuration for a fleet of managed agent nodes.
OpenVox Server performs the role of the primary server: it compiles catalogs, serves files, manages certificates, and receives reports from agents.
It is a Ruby and Clojure application that runs on the Java Virtual Machine (JVM), executing catalog compilation inside JRuby interpreters
with supporting services written in Clojure, coordinated by the Trapperkeeper service framework.

This page describes the run environment and architecture of OpenVox Server. For practical instructions, see the docs for [installing](./install_from_packages.html) and [configuring](./configuration.html) it.

## Supported Platforms

OpenVox Server packages are available for Debian, Ubuntu, Red Hat Enterprise Linux and its derivatives, Amazon Linux, Fedora, SLES, and RHEL FIPS.
For the full list of supported distributions, versions, and architectures, see [Before you begin](./install_pre.html).

OpenVox Server requires Java 17 or 21. It does not bundle a JDK; install one from your distribution's repositories before installing OpenVox Server.

OpenVox Server releases are versioned separately from OpenVox (the agent). Major versions are aligned: OpenVox Server 8.x is compatible with OpenVox 8.x.

## Controlling the Service

The OpenVox Server service name is `puppetserver`. On systemd-based platforms:

```shell
systemctl start puppetserver
systemctl stop puppetserver
systemctl restart puppetserver
systemctl status puppetserver
systemctl enable puppetserver   # start automatically on boot
```

On older SysV-style init systems, use `service puppetserver start|stop|restart|status` instead.

## OpenVox Server's Run Environment

OpenVox Server consists of several related services that share state and route requests among themselves. These services run inside a single JVM process using the Trapperkeeper service framework.
The main visible consequence of this architecture is the set of separate config files that manage the different internal services.

### Embedded Web Server

OpenVox Server uses a Jetty-based web server embedded in the service's JVM process. No additional configuration is needed for basic operation; it works out of the box and performs well under production-level loads.

The web server's settings can be modified in [`webserver.conf`](./config_file_webserver.html). You may need to edit this file if you're [using an external CA][external_ca] or running on a non-standard port.

### OpenVox API Service

OpenVox Server includes a service that handles agent configuration requests. See [OpenVox HTTP API](/openvox/latest/http_api/http_api_index.html) for documentation on the core APIs.

For OpenVox Server-specific APIs hosted by this service, see:

- [The `environment_classes` endpoint](./puppet-api/v3/environment_classes.html)
- [The `environment_modules` endpoint](./puppet-api/v3/environment_modules.html)

### Certificate Authority Service

OpenVox Server includes a certificate authority (CA) service that:

- Accepts certificate signing requests (CSRs) from nodes
- Serves certificates and a certificate revocation list (CRL) to nodes
- Optionally accepts commands to sign or revoke certificates (disabled by default)

The relevant endpoints are `certificate`, `certificate_request`, `certificate_revocation_list`, and `certificate_status`. See [CA HTTP API](/openvox/latest/http_api/http_api_index.html) for details.

Signing and revoking certificates over the network is disallowed by default. You can use [`auth.conf`](./config_file_auth.html) to allow specific certificate owners to issue commands.

The CA service stores credentials as `.pem` files under `/etc/puppetlabs/puppetserver/ca/`. Use the `puppetserver ca` command to list, sign, and revoke certificates.
See [`ca.conf`](./config_file_ca.html) for CA configuration options.

### Admin API Service

OpenVox Server includes an administrative API for triggering maintenance tasks.

The primary use case is deploying new Puppet code without restarting the service: the environment cache endpoint expires all cached environments,
causing OpenVox Server to pick up code changes on the next agent run.

For API docs, see:

- [The `environment-cache` endpoint](./admin-api/v1/environment-cache.html)
- [The `jruby-pool` endpoint](./admin-api/v1/jruby-pool.html)

For details about environment caching, see [Environments](/openvox/latest/environments_about.html).

### JRuby Interpreters

Most of OpenVox Server's work — compiling catalogs, receiving reports, etc. — is done by Ruby code. Rather than using the OS's MRI Ruby runtime,
OpenVox Server runs this code in JRuby, an implementation of the Ruby interpreter that runs on the JVM.

Because OpenVox Server does not use system Ruby, you cannot use the system `gem` command to install Ruby gems for use by OpenVox modules or extensions.
Instead, use the `puppetserver gem` command. See [Using Ruby Gems](./gems.html) for details.

The `puppetserver ruby` and `puppetserver irb` commands run Ruby code in a JRuby environment and are useful for testing or debugging code that will run on the server.
The `JAVA_ARGS_CLI` environment variable controls Java arguments passed to these commands
(set it in `/etc/sysconfig/puppetserver` or `/etc/default/puppetserver`). See [Subcommands](./subcommands.html) for details.

To handle parallel requests, OpenVox Server maintains several JRuby interpreters, each independently running OpenVox's application code, and distributes agent requests among them.

Configure the JRuby interpreters in the `jruby-puppet` section of [`puppetserver.conf`](./config_file_puppetserver.html).

#### Tuning Guide

You can maximize OpenVox Server's performance by tuning your JRuby configuration. See the [Tuning Guide](./tuning_guide.html) for details.

### User

OpenVox Server runs as the `puppet` user. This is specified in `/etc/sysconfig/puppetserver` on RPM-based systems,
or `/etc/default/puppetserver` on Debian-based systems. OpenVox Server ignores the `user` and `group` settings in `puppet.conf`.

All of OpenVox Server's files and directories must be readable and writable by the `puppet` user.

### Ports

By default, OpenVox Server listens on TCP port **8140** for HTTPS traffic. Your OS and firewall must allow the JVM process to accept incoming connections on this port.

You can change the port in `webserver.conf` if necessary. See [webserver.conf](./config_file_webserver.html) for details.

### Logging

All of OpenVox Server's logging is routed through the JVM [Logback](http://logback.qos.ch/) library. Log files are written to `/var/log/puppetlabs/puppetserver/`:

- `puppetserver.log` — main log, default level INFO
- `puppetserver-access.log` — HTTP access log
- `puppetserver-status.log` — status API requests

By default, OpenVox Server sends nothing to syslog. All log messages follow the same path, including HTTP traffic, catalog compilation, and certificate processing.

Logback archives log files when they exceed 200 MB, and automatically deletes the oldest logs when the total size of all server logs exceeds 1 GB.

Logback is highly configurable via [`logback.xml`](./config_file_logbackxml.html); see [the configuration docs](./configuration.html#logging) for details on customizing log output.

Errors that occur before logging is set up, or that cause the logging system to fail, appear in `journalctl` on systemd-based platforms.

### SSL Termination

By default, OpenVox Server handles SSL termination automatically.

In network configurations that require external SSL termination (e.g. with a hardware load balancer), additional configuration is needed.
See the [External SSL Termination](./external_ssl_termination.html) page for details. In summary:

- Configure OpenVox Server to use HTTP instead of HTTPS.
- Configure OpenVox Server to accept SSL information via HTTP headers.
- Secure your network so that OpenVox Server **cannot** be directly reached by **any** untrusted clients.
- Configure your SSL-terminating proxy to set these HTTP headers:
  - `X-Client-Verify` (mandatory)
  - `X-Client-DN` (mandatory for client-verified requests)
  - `X-Client-Cert` (optional; required for [trusted facts](/openvox/latest/lang_facts_and_builtin_vars.html))

## Configuring OpenVox Server

OpenVox Server uses a combination of OpenVox's standard config files and its own configuration files located in the `conf.d` directory.

The `conf.d` directory contains:

- `global.conf` — global configuration settings
- `webserver.conf` and `web-routes.conf` — web server settings
- `puppetserver.conf` — JRuby interpreter and admin API settings
- `auth.conf` — authentication rules for server endpoints
- `ca.conf` — certificate authority settings

For full details, see the [Configuration](./configuration.html) page.

OpenVox Server also uses OpenVox's standard config files, including most settings in [`puppet.conf`](/openvox/latest/config_file_main.html).
However, some `puppet.conf` settings are treated differently by OpenVox Server — see [puppet.conf differences](./puppet_conf_setting_diffs.html) for details.
