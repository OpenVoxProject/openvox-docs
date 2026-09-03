---
layout: default
title: "Upgrading from OpenVox 8 to OpenVox 9"
---

OpenVox 9 is a major release, but it does not change the Puppet language. Its focus is updating the platform underneath OpenVox: newer Ruby, OpenSSL, JRuby, and Java, plus the removal of settings and behaviors deprecated in OpenVox 8. Most Puppet code that runs cleanly on OpenVox 8 runs unchanged on OpenVox 9, but review the component upgrades and removals below before upgrading a production deployment.

This page covers what to check and change before the upgrade. For the package mechanics of the upgrade itself, see [Upgrading OpenVox 9](upgrade_minor.html).

> **OpenVox 9 is in prerelease.** Details on this page can still change before the stable 9.0.0 release. See the [release notes](release_notes.html) and [known issues](known_issues.html) for the current state of the prerelease builds.

## What changes in OpenVox 9

The major version bump comes from the underlying components:

| Component | OpenVox 8 | OpenVox 9 |
| --------- | --------- | --------- |
| Ruby (bundled with `openvox-agent`) | 3.2 | 4.0 |
| OpenSSL (bundled with `openvox-agent`) | 3.0 | 3.5 |
| OpenFact (bundled with `openvox-agent`) | 5.x | 6.x |
| JRuby (bundled with `openvox-server`) | 9.4 | 10.1 |
| Java (required by `openvox-server` and `openvoxdb`) | 17 or 21 | 21 or 25 |

See [Component versions in recent releases](component_versions.html) for the exact versions in each release.

## Before you upgrade

1. Upgrade your deployment to the latest OpenVox 8 release first and resolve any deprecation warnings in agent and server logs. Most of what OpenVox 9 removes was already deprecated in the 8.x series.
2. Read the release notes for each component: [OpenVox 9](release_notes.html), [OpenVox Server 9](/openvox-server/9.x/release_notes.html), [OpenVoxDB 9](/openvoxdb/9.x/release_notes.html), and [OpenFact 6](/openfact/6.x/release_notes.html). Each links to the GitHub release page with the full list of changes.
3. Check that packages exist for your platforms on the [supported platforms](supported_platforms.html) page. OpenVox Server 9 and OpenVoxDB 9 no longer publish packages for Debian 11 and 12, which only provide Java 17, and OpenVox Server 9 also drops Amazon Linux 2.
4. Back up `/etc/puppetlabs/` on your servers and take a database backup of OpenVoxDB with `pg_dump` before starting.

## Review Ruby code for Ruby 4.0

The agent's bundled Ruby moves from 3.2 to 4.0. Everything that runs inside the agent's Ruby must be compatible with Ruby 4.0:

- Custom facts, functions, types, and providers in your modules
- Gems you install into the agent with `puppet_gem` or `/opt/puppetlabs/puppet/bin/gem`

Ruby 4.0 removes APIs that were deprecated during the Ruby 3.x series. A common one in older facts and providers is spawning a subprocess with `Kernel#open` and a pipe argument (`open("|command")`), which no longer works; use `IO.popen` or, better, OpenFact's `Facter::Core::Execution.execute` for fact code. Run your module unit tests on Ruby 4.0 to find problems before the upgrade.

OpenVox Server 9 bundles JRuby 10.1, which targets the same Ruby 4.0 language level. Ruby code that runs on the server, such as report processors, custom indirector termini, and gems installed with `puppetserver gem`, needs the same review.

If you install OpenVox as a gem rather than from packages, the `openvox` gem now requires at least Ruby 3.2.

## Review custom facts for OpenFact 6

`openvox-agent` 9 bundles and requires OpenFact 6, a major version bump from the 5.x series bundled with OpenVox 8. Test your custom and external facts against OpenFact 6. The changes most likely to affect fact code:

- OpenFact 6 requires Ruby 3.0 or later, which the agent's Ruby 4.0 satisfies; fact code that also runs elsewhere needs the same floor.
- `Facter::Core::Execution.exec`, `Facter::Util::Resolution.exec`, and `Facter::Util::Resolution.which` now log a deprecation warning ahead of removal. Use `Facter::Core::Execution.execute` and `Facter::Core::Execution.which`.
- The `time_limit` and `limit` option keys for `execute` are deprecated aliases; use `timeout`.
- The deprecated `ldapname` fact option is removed.
- When a fact calls a bare command name, OpenFact now also searches `/opt/puppetlabs/bin`, so facts that call `puppet`, `puppetserver`, or `puppetdb` resolve when the agent runs as a service.

See the [OpenFact 6 release notes](/openfact/6.x/release_notes.html) for the full list.

## Deferred functions are preprocessed again by default

OpenVox 8 evaluated deferred functions (functions called through the `Deferred` data type) lazily, at the moment the catalog applied the resource that used them. OpenVox 9 returns to the older behavior of resolving all deferred functions up front, before catalog application starts.

This matters if a deferred function depends on something the same run puts in place, for example a package or library installed earlier in the catalog. Under preprocessing, the function runs before that prerequisite exists and the run fails. If you depend on lazy evaluation, set `preprocess_deferred = false` in the agent's `puppet.conf` to keep the OpenVox 8 behavior.

## Report storage is now opt-in

The default for the [`reports` setting](configuration.html#reports) changed from `store` to `none`, so an upgraded server stops writing YAML report files to the reports directory. If you rely on stored reports, or on tooling that reads them, set the value explicitly on the server:

```ini
[server]
reports = store
```

Report submission from agents is unchanged; only the server-side default for processing them changed.

## Agents must have an explicit server setting

OpenVox 8 agents fell back to contacting a host named `puppet` when no server was configured. OpenVox 9 deprecates this fallback: root agents still use it but log a deprecation warning, and `puppet` commands run as a non-privileged user fail instead of falling back. If any nodes still rely on the fallback, set the [`server` setting](configuration.html#server) explicitly before upgrading them:

```console
puppet config set server openvox.example.com --section main
```

## Removed settings

These settings are gone in OpenVox 9. Remove them from `puppet.conf` and from any scripts or tooling that reference them before you upgrade:

- `configprint`: use `puppet config print <SETTING>` instead of `puppet agent --configprint <SETTING>`.
- `pluginsync`: plugins always sync; the setting had been deprecated since Puppet 6.
- `data_binding_terminus` and `environment_data_provider`: the classic `hiera` indirector and pluggable data bindings are removed. Automatic class parameter lookup always uses the modern lookup system. If you still maintain a Hiera 3 `hiera.yaml`, see [Migrating your Hiera configuration](hiera_migrate.html); Hiera 3 backends keep working through a version 5 `hiera.yaml`.

## Other removals

- The `regsubst` function no longer accepts its deprecated encoding argument.
- The `pe_serverversion` fact is removed.
- The `zone_core` module for Solaris zones is no longer vendored with the agent. Install [`puppetlabs-zone_core`](https://forge.puppet.com/modules/puppetlabs/zone_core) from the Forge if you manage `zone` resources.
- The agent runtime no longer ships Java keystore files, and legacy PAL script-evaluation APIs are removed. See the [release notes](release_notes.html) if you depend on either.

## Server and OpenVoxDB changes

- **Java:** OpenVox Server 9 and OpenVoxDB 9 drop support for Java 17. Install Java 21 or 25 before upgrading the server packages.
- **Filebucket reads need an administrative certificate:** the default `auth.conf` in OpenVox Server 9 lets agents store filebucket content (`HEAD` and `PUT`) but restricts reading it back (`GET` and `POST`) to client certificates with the `pp_cli_auth: "true"` extension.
  If you restore or diff filebucket content remotely with an ordinary agent certificate, add an `auth.conf` rule for that certname before upgrading. See [auth.conf](/openvox-server/9.x/config_file_auth.html).
- **Jetty 12:** both OpenVox Server 9 and OpenVoxDB 9 move to Jetty 12. If you customized `webserver` settings beyond host and port, review them after the upgrade.
  For OpenVoxDB, if you upgrade from 8.14.0 or earlier and have modified `/etc/puppetlabs/puppetdb/bootstrap.cfg`, the package manager keeps your copy and the service fails to start because it still loads `jetty10-service`; the [OpenVoxDB 9 release notes](/openvoxdb/9.x/release_notes.html) have the fix.
- **PostgreSQL:** OpenVoxDB 9 requires PostgreSQL 14 or later, the same minimum as the last 8.x releases.
- **Packaging:** the `openvox-server` 9 package requires `openvox-agent` 9 on the same host, so the server host's agent upgrades along with it.

## Test, then upgrade

1. Run your module unit tests on Ruby 4.0 and fix any failures.
2. Validate your manifests with `puppet parser validate`.
3. Stand up an OpenVox 9 server in a test environment, point test agents at it, and compare `puppet agent --test --noop` output against OpenVox 8 for unexpected changes.
4. Upgrade production in the usual order: `openvox-server`, then `openvoxdb` and `openvoxdb-termini`, then agents. OpenVox 8 agents can keep checking in to an upgraded OpenVox 9 server while you roll out agent upgrades. [Upgrading OpenVox 9](upgrade_minor.html) has the package commands.
