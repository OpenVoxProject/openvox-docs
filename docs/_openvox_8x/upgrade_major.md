---
layout: default
title: "Upgrading from Puppet 7 to OpenVox 8"
---

OpenVox 8 does not change the Puppet language, but it turns on stricter defaults, stops sending legacy facts, and updates Ruby and OpenSSL. Code that compiles on Puppet 7 or OpenVox 7 can fail on OpenVox 8, and some of it keeps compiling but produces a different catalog.

This page covers what to check and change before the upgrade. It applies to both Puppet 7 and OpenVox 7. For the package commands, see [Upgrading OpenVox 8](upgrade_minor.html).

## Choose a path

| Starting from | Path |
| ------------- | ---- |
| Puppet 7 or OpenVox 7 | Follow this page, then upgrade in place. |
| Puppet 6 or older | Rebuild. Install new OpenVox 8 infrastructure, starting from [Getting started with OpenVox](getting_started.html), update your code until it compiles there, and move your nodes to it. |

OpenVox has no release older than 7, so an in-place upgrade from Puppet 6 or older would pass through several Puppet versions that are no longer maintained. For those versions, rebuild instead of upgrading in place: [Getting started with OpenVox](getting_started.html) covers installing the server, enrolling agents, and setting up a control repository.
This page does not cover the changes between those versions. The sections below still apply to your code when you move it to the new servers. For the older release notes, see the [Puppet docs archive](https://github.com/puppetlabs/docs-archive).

## What changes in OpenVox 8

| Component | Puppet 7 and OpenVox 7 | OpenVox 8 |
| --------- | ---------------------- | --------- |
| Ruby (bundled with `openvox-agent`) | 2.7 | 3.2 |
| OpenSSL (bundled with `openvox-agent`) | 1.1.1 | 3.0 |
| Facts (bundled with `openvox-agent`) | Facter 4.x | OpenFact 5.x |
| JRuby (bundled with `openvox-server`) | 9.3 | 9.4 |
| Java (required by `openvox-server` and `openvoxdb`) | 8, 11, or 17 | 17 or 21 |
| PostgreSQL (required by `openvoxdb`) | 11 or later | 14 or later |

See [Component versions in recent releases](component_versions.html) for the exact versions in each release.

These settings have new defaults:

| Setting | Default in 7 | Default in 8 | Applies on |
| ------- | ------------ | ------------ | ---------- |
| [`strict`](configuration.html#strict) | `warning` | `error` | Server |
| [`strict_variables`](configuration.html#strict_variables) | `false` | `true` | Server |
| [`include_legacy_facts`](configuration.html#include_legacy_facts) | `true` | `false` | Agent |
| [`preprocess_deferred`](configuration.html#preprocess_deferred) | `true` | `false` | Agent |
| [`exclude_unchanged_resources`](configuration.html#exclude_unchanged_resources) | `false` | `true` | Agent |
| [`crl_refresh_interval`](configuration.html#crl_refresh_interval) | Not set | 1 day | Agent |

The "Applies on" column matters during a rollout. Settings that apply on the server change behavior for every node as soon as you upgrade the server, including nodes that still run a 7 agent. Settings that apply on the agent change behavior node by node as you upgrade each agent. With `puppet apply`, every setting applies on the node.

## Before you upgrade

1. Upgrade to the latest 7.x release first and resolve the deprecation warnings in your agent and server logs. You need Puppet 7.21.0 or later, or any OpenVox 7 release, to [rehearse the new defaults](#rehearse-the-new-defaults-on-7).
2. Read the release notes for each component: [OpenVox 8](release_notes.html), [OpenVox Server 8](/openvox-server/latest/release_notes.html), and [OpenVoxDB 8](/openvoxdb/latest/release_notes.html).
3. Check that packages exist for your platforms on the [supported platforms](supported_platforms.html) page.
4. Plan the order: OpenVox Server first, then OpenVoxDB and `openvoxdb-termini`, then the agents. A 7 agent works with an 8 server, so agents can follow over days or weeks. An 8 agent against a 7 server fails as soon as the server falls back to PSON for a catalog. Don't upgrade any agent before its server. See [Mixed versions](#mixed-versions).
5. Back up `/etc/puppetlabs/` on your servers and take a database backup of OpenVoxDB with `pg_dump`.

## Strict mode is on by default

[`strict`](configuration.html#strict) now defaults to `error` and [`strict_variables`](configuration.html#strict_variables) to `true`. Code that logged a warning on 7 now fails compilation:

| Code | On 7 | On 8 |
| ---- | ---- | ---- |
| `notice($myvar)`, where `$myvar` is never assigned | Warning, value is empty | `Evaluation Error: Unknown variable: 'myvar'.` |
| `notice("1" + 1)` | Warning, result is `2` | `Evaluation Error: The string '1' was automatically coerced to the numerical value 1` |

Both settings apply where the catalog is compiled. An upgraded server enforces them for every agent, whatever version the agent runs.

Fix the code where you can. If you need more time, restore the 7 behavior on the server:

```ini
[server]
strict = warning
strict_variables = false
```

Set both. Changing only one of them still fails on an undefined variable. `puppet config set` writes the same settings without editing the file:

```console
puppet config set strict warning --section server
puppet config set strict_variables false --section server
```

To change a setting on many nodes at once, the [`puppet_conf`](https://forge.puppet.com/modules/puppetlabs/puppet_conf) task runs the same command through OpenBolt.
The [`openvox_bootstrap::configure`](https://github.com/voxpupuli/puppet-openvox_bootstrap#openvox_bootstrapconfigure) task does the same from a hash of sections and settings. It also starts and enables the agent service unless you set `puppet_service_running` and `puppet_service_enabled` to `false`.

## Legacy facts are no longer sent

OpenVox 8 agents don't send legacy facts such as `osfamily`, `fqdn`, and `ipaddress_eth0`. Use the structured facts instead, for example `$facts['os']['family']`. [Core facts](/openfact/latest/core_facts.html#legacy-facts) lists the legacy facts.

The legacy facts still exist on the node, and asking for one by name always resolves it: `facter osfamily` and `puppet facts show osfamily` print a value on an OpenVox 8 agent with `include_legacy_facts = false`.
Only full fact sets leave them out. `facter` and `puppet facts show` omit them unless you add `--show-legacy`, and the facts the agent sends to the server for catalog compilation omit them unless `include_legacy_facts` is `true`.
A legacy fact that resolves on the command line says nothing about what the server sees. Compile a catalog, or check the node's facts in OpenVoxDB, which stores what the agent sent.

How a leftover reference behaves depends on how it is written. Some forms fail the run. Others resolve to nothing without any message, and the catalog changes.

| Where | Reference | On 8 |
| ----- | --------- | ---- |
| Manifest or EPP template | `$::osfamily` or `$osfamily` | Fails: `Unknown variable: '::osfamily'.` |
| Manifest or EPP template | `$facts['osfamily']` | No error. The value is `undef`. |
| ERB template | `scope['::osfamily']` or `scope.lookupvar('::osfamily')` | Fails: `Undefined variable '::osfamily'` |
| ERB template | `@osfamily` or `@facts['osfamily']` | No error. The value is empty. |
| `hiera.yaml` hierarchy path | `%{::osfamily}` or `%{osfamily}` | Warning. The hierarchy level is skipped. |
| `hiera.yaml` hierarchy path | `%{facts.osfamily}` | No message. The hierarchy level is skipped. |
| Hiera data value | `%{::osfamily}` or `%{osfamily}` | Fails: `Undefined variable '::osfamily'` |
| Hiera data value | `%{facts.osfamily}` | No error. The value is empty. |

The forms that don't fail need the most attention. A condition such as `if $facts['osfamily'] == 'Debian'` stops matching and the `else` branch applies. A hierarchy level built on a legacy fact stops matching, and the node gets its data from the next level down. The only sign in the log is this warning, and only for the forms that produce one:

```text
Warning: Interpolation failed with '::osfamily', but compilation
continuing;
```

Legacy facts are controlled by the agent, so this change takes effect one node at a time. A 7 agent keeps sending legacy facts to an 8 server, and the same code starts behaving differently for a node when you upgrade its agent.

### Find legacy facts

The `legacy_facts` check in [puppet-lint](/ecosystem/latest/devkit/linting.html) finds legacy facts in manifests and in YAML files, which covers `hiera.yaml` and your Hiera data. Give it one directory, such as the root of your control repository, and it checks every `.pp`, `.yaml`, and `.yml` file below it:

```console
puppet-lint --only-checks legacy_facts .
```

Give puppet-lint one directory or a list of files. If you give it several directories, it checks only the first one.

It can also rewrite the manifests. Run `--fix` on manifests only. puppet-lint does not fix YAML files, and version 5.1.1 stops with an error when `--fix` reaches a YAML file that contains a legacy fact:

```console
find . -name '*.pp' -exec \
  puppet-lint --only-checks legacy_facts --fix {} +
```

The check has limits:

- It fixes manifests only. It reports legacy facts in YAML files, from puppet-lint 4.3.0 on, and you change those by hand.
- It does not check `.eyaml` files, ERB or EPP templates, or Ruby code.
- It finds `$::osfamily` and `$facts['osfamily']`, but not `$osfamily` without the leading `::`. Strict mode catches that form, because it fails compilation.
- It can't rewrite 11 of the legacy facts. See [Facts you change by hand](#facts-you-change-by-hand).
- The `lint` and `lint_fix` Rake tasks in a module cover manifests only. Run `puppet-lint` directly to check YAML files.

[rowlf](https://gitlab.wikimedia.org/repos/sre/rowlf) is a newer tool from Wikimedia's SRE team that rewrites legacy facts in manifests, EPP and ERB templates, Hiera YAML, and Ruby functions, including every fact puppet-lint can't except `zones`. It also updates some stdlib calls, such as `has_key` to the `in` operator.
With `-u` it also rewrites `$osfamily` without the leading `::`, the form puppet-lint skips, and it leaves alone any variable your code declares with the same name as a fact.
It is built from source with Go. Run it with `-d` and review the diff before you use `-i` to edit files in place.

Neither tool checks `.eyaml` files, and neither reads every form a template can use. Search those yourself. This finds the common forms of the facts you name in `FACTS`:

```console
FACTS='osfamily|operatingsystem|fqdn|hostname|ipaddress'
grep -rnE "(@|::|%\{|facts[.[]'?)($FACTS)" \
  --include='*.erb' --include='*.epp' --include='*.eyaml' .
```

### Facts you change by hand

The check can't rewrite these legacy facts, because no structured fact holds the same value. The list is `UNCONVERTIBLE_FACTS` in the [source of the check](https://github.com/puppetlabs/puppet-lint/blob/v5.1.1/lib/puppet-lint/plugins/legacy_facts/legacy_facts.rb#L14-L17).
rowlf rewrites all of these except `zones`, from its 2026-10-02 commits on. The table is for the ones you fix by hand after puppet-lint, or for checking rowlf's output.

| Legacy fact | Value | Build it from |
| ----------- | ----- | ------------- |
| `memorysize_mb`, `memoryfree_mb` | Size in MiB (1 MiB is 1,048,576 bytes) | `total_bytes` and `available_bytes` in `$facts['memory']['system']`, divided by 1048576.0 |
| `swapsize_mb`, `swapfree_mb` | Size in MiB (1 MiB is 1,048,576 bytes) | `total_bytes` and `available_bytes` in `$facts['memory']['swap']`, divided by 1048576.0 |
| `blockdevices` | Comma-separated names | `$facts['disks'].keys.join(',')` |
| `interfaces` | Comma-separated names | `$facts['networking']['interfaces'].keys.join(',')` |
| `sshfp_dsa`, `sshfp_ecdsa`, `sshfp_ed25519`, `sshfp_rsa` | Both fingerprints, one per line | `sha1` and `sha256` in `$facts['ssh']['rsa']['fingerprints']`, and the same for the other key types |
| `zones` | Number of Solaris zones | The number of entries in `$facts['solaris_zones']['zones']` |

With `--fix`, puppet-lint reports each of these as `FIXED` and leaves most of them as they were. Search for the 11 names after you run it.

> **Note:** Inside a double-quoted string, `--fix` damages the `$facts` form of these facts. It turns `"${facts['sshfp_rsa']}"` into `"${facts}"`, which still compiles and puts the whole facts hash in the string. Review the diff before you commit the result.

### Keep legacy facts

If you can't update everything before the upgrade, turn legacy facts back on. Set this on each agent:

```ini
[agent]
include_legacy_facts = true
```

Or run `puppet config set include_legacy_facts true --section agent`.

## Hiera 3 is no longer included

The Hiera 3 gem is not part of the OpenVox 8 packages. What that means depends on what you use:

| You use | On 8 |
| ------- | ---- |
| A version 5 `hiera.yaml` with the built-in backends | No change. |
| A version 3 `hiera.yaml` with the `yaml`, `json`, or `eyaml` backend | Works, with a deprecation warning. |
| A custom Hiera 3 backend, through a version 3 `hiera.yaml` or `hiera3_backend` | Fails: `Hiera 3 is not installed` |

`hiera-eyaml` is included in the OpenVox 8 agent package.

Convert custom Hiera 3 backends to Hiera 5. See [Writing new data backends](hiera_custom_backends.html). To convert a version 3 `hiera.yaml`, see [Migrating your Hiera configuration](hiera_migrate.html).

## Binary file content needs the Binary type

OpenVox 8 removes the PSON serialization format. On 7, a catalog that could not be written as JSON was sent as PSON instead. The usual cause is a file's `content` holding bytes that are not valid UTF-8:

```puppet
file { '/opt/app/logo.png':
  content => file('app/logo.png'),
}
```

On 8 the server fails the catalog request:

```text
Error: Could not retrieve catalog from remote server: Error 500 on
SERVER: Server Error: Failed to serialize Puppet::Resource::Catalog
for 'agent.example.com': Could not render to
Puppet::Network::Format[rich_data_json]: source sequence is
illegal/malformed utf-8
```

To find affected nodes before you upgrade, search your 7 agent logs for the fallback message:

```text
Info: Unable to serialize catalog to json, retrying with pson.
```

Use [`binary_file`](lang_data_binary.html) in place of `file`, or serve the file with the `source` attribute:

```puppet
file { '/opt/app/logo.png':
  content => binary_file('app/logo.png'),
}
```

## Review Ruby code for Ruby 3.2

The agent's Ruby moves from 2.7 to 3.2. Everything that runs inside it needs to work on Ruby 3.2:

- Custom facts, functions, types, and providers in your modules
- Gems you install into the agent with `puppet_gem` or `/opt/puppetlabs/puppet/bin/gem`

Ruby 3 removed methods that older code often uses:

- `taint` and `untaint`. Remove the calls.
- `File.exists?` and `Dir.exists?`. Use `File.exist?` and `Dir.exist?`. OpenVox defines the old names when it loads, so code that calls them keeps working during an agent run. The same fact fails when you run `facter` on its own.
- Passing a hash where a method expects keyword arguments. Ruby 3 separates positional and keyword arguments, and the usual symptom is `wrong number of arguments`.

A custom fact that raises an error does not fail the agent run. The agent logs the error and the fact resolves to nothing, so code that depends on the fact changes behavior:

```text
Error: Facter: Error while resolving custom fact fact='app_installed',
resolution='<anonymous>': undefined method `untaint' for
"/opt/app":String
```

Run `puppet facts show` on a test node after the upgrade and check its output for errors.

OpenVox Server 8 bundles JRuby 9.4, which moves the server's Ruby from the 2.6 language level to 3.1. Review Ruby code that runs on the server the same way: functions, report processors, and custom Hiera backends. Keep that code at Ruby 3.1 syntax. If rubocop targets 3.2 and rewrites a server-side function to newer syntax, the server can't load it.

## Reinstall gems added to the agent's Ruby

Gems are installed into a directory named after the Ruby version. Gems you added on 7 are in `/opt/puppetlabs/puppet/lib/ruby/gems/2.7.0/`. Ruby 3.2 looks in `/opt/puppetlabs/puppet/lib/ruby/gems/3.2.0/` and does not see them. The upgrade leaves the old directory in place.

Before you upgrade, list the gems you added:

```console
/opt/puppetlabs/puppet/bin/gem list --local
```

After you upgrade, reinstall each one with `sudo /opt/puppetlabs/puppet/bin/gem install <NAME>`. When nothing depends on it, you can delete the `2.7.0` directory.

Gems installed into OpenVox Server with `puppetserver gem` are stored in `/opt/puppetlabs/server/data/puppetserver/jruby-gems`, which is not named after a Ruby version, so they stay installed. Review them for compatibility with JRuby 9.4.

## Other changes

- **Deferred functions run during the catalog run.** On 7, the agent called every deferred function before it applied the catalog. On 8, a deferred function runs when the resource that uses it is applied, so it can depend on something the same run installs. Set `preprocess_deferred = true` on the agent to keep the 7 behavior.
- **Reports leave out unchanged resources.** An 8 agent leaves resources that did not change out of its report. Queries and dashboards that count every resource in a report show lower numbers. Set `exclude_unchanged_resources = false` on the agent to report every resource.
- **The agent refreshes its CRL once a day.** See [`crl_refresh_interval`](configuration.html#crl_refresh_interval).
- **OpenSSL 3.0.** The agent no longer includes the `c_rehash` script. Use `/opt/puppetlabs/puppet/bin/openssl rehash`. Rebuild anything you compiled against the agent's OpenSSL libraries.

## Server and OpenVoxDB changes

The OpenVox 8 packages replace the Puppet 7 packages directly: `openvox-server` replaces `puppetserver`, `openvoxdb` replaces `puppetdb`, and `openvoxdb-termini` replaces `puppetdb-termini`. You don't need to install OpenVox 7 first. Each of the three also requires `openvox-agent`, so the agent on those hosts is upgraded in the same step.
[Upgrading OpenVox Server](/openvox-server/latest/upgrade_minor.html) and [Upgrading OpenVoxDB](/openvoxdb/latest/upgrade.html) have the package commands. Before you run them, know about these changes:

- **Java:** OpenVox Server 8 and OpenVoxDB 8 require Java 17 or 21. The packages pull in a suitable JRE, but they don't change which `java` the host runs by default. If Puppet Server 7 ran on Java 11, `/usr/bin/java` still points at 11 after the upgrade, and the service exits at startup:

  ```text
  Execution error (UnsupportedClassVersionError) ...
  com/puppetlabs/ssl_utils/ExtensionsUtils$AttributeDescriptor has
  been compiled by a more recent version of the Java Runtime (class
  file version 61.0), this version of the Java Runtime only
  recognizes class file versions up to 55.0
  ```

  Select the new Java with `update-alternatives --config java` on Debian and Ubuntu or `alternatives --config java` on EL, or set `JAVA_BIN` in the service defaults file (`/etc/default/puppetserver` and `/etc/default/puppetdb`, or `/etc/sysconfig/` on EL). Then start the service.
- **Configuration files:** files you edited are kept, and the package manager asks about each one it wants to update. Files you never edited, such as the default `auth.conf`, `ca.conf`, and `puppetserver.conf` in `/etc/puppetlabs/puppetserver/conf.d`, are replaced by the OpenVox 8 versions.
  `puppetdb.conf`, `routes.yaml`, the OpenVoxDB `database.ini`, and the CA and certificate directories are not touched. Look for `.dpkg-dist` or `.rpmnew` files under `/etc/puppetlabs` and `/etc/default` afterwards.

  `puppet.conf` is the exception. The package manager treats the replacement as a fresh install of `openvox-server`, and the package's install hook sets `vardir`, `logdir`, `rundir`, `pidfile`, and `codedir` in the `[server]` section to the package defaults.
  The server process itself reads those directories from the `server-code-dir`, `server-var-dir`, `server-run-dir`, and `server-log-dir` settings in `puppetserver.conf`, which the upgrade keeps, so it compiles from the same code directory as before. The `puppet.conf` values matter to `puppet` commands you run on the server host with `--section server`. If you had custom values there, put them back.
- **OpenVoxDB `bootstrap.cfg`:** if you edited `/etc/puppetlabs/puppetdb/bootstrap.cfg` on 7, for example to remove the dashboard redirect, the kept file still loads the `jetty9-service` web server, which OpenVoxDB 8 no longer has, and the service fails to start.
  On the web server line, change `jetty9-service` to `jetty-service` in both the namespace and the service name, or start from the `.dpkg-dist` file and reapply your edits.

  In an unattended run, a conffile question that nothing answers leaves `openvox-server` unpacked but not configured, and `apt-get` exits with an error. `dpkg --configure -a --force-confold` finishes the installation and keeps your files.
- **OpenVoxDB migrates the database on first start.** OpenVoxDB 8 supports PostgreSQL 14 or later. It still starts on 11, 12, and 13, but logs an error at startup that the version is unsupported, and it refuses to start on anything older.
  Upgrade PostgreSQL first, install the `pg_trgm` extension if the database does not have it, and take a backup with `pg_dump`. The schema migration runs the first time OpenVoxDB 8 starts and keeps the existing nodes, facts, catalogs, and reports. How long it takes depends on the size of the database. See [Configuring PostgreSQL](/openvoxdb/latest/configure_postgres.html).
- **Server-side gems:** gems installed with `puppetserver gem` stay installed, as described in [Reinstall gems added to the agent's Ruby](#reinstall-gems-added-to-the-agents-ruby).

### Mixed versions

Upgrade OpenVox Server before any agent, and upgrade OpenVoxDB and `openvoxdb-termini` in the same maintenance window as the server, so the server and OpenVoxDB don't run different major versions for longer than the upgrade takes.
Agents can't get catalogs while the server is being upgraded. If you have compilers behind a load balancer, upgrade the primary server first and then the compilers one at a time.
A 7 agent works with an 8 server, so you can upgrade the server first and the agents over time. The reverse doesn't hold: an 8 agent can't accept the PSON catalogs that a 7 server falls back to, and the request fails with `Error 406 on SERVER: Not Acceptable`.
It also means the strict mode change reaches every node on the day you upgrade the server, while the legacy facts change reaches each node when you upgrade its agent, as described under [What changes in OpenVox 8](#what-changes-in-openvox-8).

## Test, then upgrade

### Rehearse the new defaults on 7

You can turn on the OpenVox 8 defaults while you are still on 7. Start with one environment or a few test nodes.

On the server:

```ini
[server]
strict = error
strict_variables = true
```

On the agents:

```ini
[agent]
include_legacy_facts = false
```

With `puppet config set`, that is `puppet config set strict error --section server`, `puppet config set strict_variables true --section server`, and `puppet config set include_legacy_facts false --section agent`.

Compilation failures show you the code that needs to change. They don't show you the references that resolve to nothing, so compare catalogs as well.

### Compare catalogs

Compile catalogs for the same nodes with the old and new settings and compare them. A resource that disappears or changes points to a condition or a Hiera lookup that depended on a legacy fact. [Impact analysis of code changes](/ecosystem/latest/devkit/impact_analysis.html) shows how to do this with Catalog Diff.

### Upgrade

1. Update your modules while you are still on 7. Every module needs a release that declares Puppet 8 or OpenVox in its `metadata.json`. The Puppet-maintained modules added Puppet 8 support in major releases during 2023 (stdlib 9, concat 8, apt 9.1, inifile 6, firewall 5),
   and those releases also removed deprecated functions such as `has_key`, `is_array`, `min`, and `dig`.
   A set that works together and still supports 7 is stdlib 9, concat 9, apt 9.1, inifile 6.1, and firewall 6.
   The first Puppet 8 releases of concat, inifile, and firewall still required stdlib below 9, so they can't be combined with apt 9.1 or stdlib 9. Update to that set first, fix what breaks, and move to the latest releases after the platform upgrade. Vox Pupuli modules declare `openvox` rather than `puppet` in their metadata since 2025, so check both names.
   The `r10k:dependencies` task from [ra10ke](https://github.com/voxpupuli/ra10ke) lists the modules in a Puppetfile that have newer releases.
2. Run your module unit tests on Ruby 3.2 and fix any failures. See [Unit testing](/ecosystem/latest/devkit/unit_testing.html).
3. Validate your manifests with `puppet parser validate`.
4. Install an OpenVox 8 server in a test environment, point test agents at it, and review the output of `puppet agent --test --noop`.
5. Switch each host to the OpenVox 8 repository. See [OpenVox repositories and packages](openvox_platform.html).

   If the host has `openvox7-release` installed, remove it first on Debian and Ubuntu. Both packages contain `/etc/apt/preferences.d/openvox-release.pref`, and `dpkg` refuses to install the second one:

   ```console
   sudo apt remove openvox7-release
   wget https://apt.voxpupuli.org/openvox8-release-ubuntu24.04.deb
   sudo dpkg -i openvox8-release-ubuntu24.04.deb
   sudo apt update
   ```

   If the host has a Puppet release package such as `puppet7-release`, installing `openvox8-release` does not remove it. Remove it after the upgrade so the host no longer points at the Puppet repository.

   Remove any version pins or holds on the Puppet packages as well: `apt-mark unhold` and pin files in `/etc/apt/preferences.d/` on Debian and Ubuntu, and the `versionlock` list on EL. A pinned `puppet-agent` or `puppetserver` blocks the replacement.
6. Upgrade production in this order: `openvox-server` first, then `openvoxdb` and `openvoxdb-termini`, then the agents. [Upgrading OpenVox 8](upgrade_minor.html) has the package commands. Installing `openvox-agent` replaces the `puppet-agent` package and keeps `puppet.conf` and the certificates in `/etc/puppetlabs/puppet/ssl`.
   After the server packages install, restart the service with `systemctl restart puppetserver`. A reload is not enough, because the agent package under the server changed too.

   If you manage agents with the [theforeman/puppet](https://forge.puppet.com/modules/theforeman/puppet) module, its `version` parameter upgrades the agent package on the next run. Switch the release repository first; the module doesn't manage it.
7. If you manage OpenVoxDB with `puppetlabs/puppetdb`, switch to [`puppet/openvoxdb`](https://forge.puppet.com/modules/puppet/openvoxdb) after OpenVoxDB is on 8. The module requires OpenVox 8.19 or later and does not support upgrading from PuppetDB versions below 8.
   Rename the `puppetdb` classes to `openvoxdb` and the `puppetdb::` Hiera keys to `openvoxdb::`. The parameters keep their names but are type checked, so a value of the wrong type that the old module accepted now fails.
   Replace the module rather than adding it alongside. The two ship the same plugin files, and agents that receive both report checksum mismatches during pluginsync.
