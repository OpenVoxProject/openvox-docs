---
layout: default
title: "Manage a service with a module"
---

One of the most common things you do with OpenVox is manage a system service: install its package, write its configuration, and keep it running.
You rarely have to write that logic yourself. The [Puppet Forge](https://forge.puppet.com) hosts thousands of reusable modules that already do it.

This guide walks through the pattern using time synchronization as the example. The same three steps work for almost any service:

1. Install a module from the Forge.
2. Declare its main class in your manifest, with any parameters you need.
3. Apply the change with an OpenVox run.

## Before you begin

You need:

- A running OpenVox Server. See [Installing OpenVox Server](/openvox-server/latest/install_from_packages.html).
- At least one OpenVox agent. See [Installing a \*nix agent](install_linux.html).
- Root or `sudo` access on both.

## Step 1: Install the module

You'll manage time synchronization with chrony, the default time service on current Linux distributions, using the Vox Pupuli [`puppet-chrony`](https://forge.puppet.com/modules/puppet/chrony) module.

On your OpenVox Server, install the module from the Forge:

```console
puppet module install puppet-chrony
```

OpenVox downloads the module into your environment's module path, `/etc/puppetlabs/code/environments/production/modules`.

`puppet module install` resolves and installs a module's dependencies automatically. Run `puppet module list` to see everything that's installed.
{: .tip }

## Step 2: Declare the class

A module exposes its behavior through [classes](lang_classes.html). Declaring the `chrony` class tells OpenVox to install chrony, manage its configuration, and keep the service running.

On your OpenVox Server, open the main manifest at `/etc/puppetlabs/code/environments/production/manifests/site.pp` and add the class to the `default` node:

```puppet
node default {
  class { 'chrony':
    servers => ['0.pool.ntp.org', '1.pool.ntp.org', '2.pool.ntp.org'],
  }
}
```

The `servers` parameter sets the upstream time sources. Every parameter a module accepts is documented on its Forge page; `servers` is the only one you need here.

{% include alert.html type="note" title="About the default node" content="The `default` node applies to every agent that doesn't match a more specific node definition.
Production deployments usually classify nodes with the roles and profiles pattern and Hiera rather than editing `site.pp` directly, but a `default` node is the quickest way to see a module work." %}

## Step 3: Apply the change

On your agent, trigger a run:

```console
puppet agent -t
```

OpenVox compiles the catalog, installs chrony if it's missing, writes its configuration, and starts the service. The output lists each change as it's applied.

## Step 4: Verify

chrony ships with the `chronyc` command, which reports its status. On the agent, check the time sources it's now using:

```console
chronyc sources
```

The output lists the servers from your manifest. To confirm the clock is synchronized, run `chronyc tracking`.

The module installs the chrony package and manages the `chronyd` service for you, so you don't have to enable or start it by hand.

## Reuse the pattern

You installed a module, declared a class, and applied it. Those same three steps manage almost any service:

- Browse the [Puppet Forge](https://forge.puppet.com) for a module that covers what you need.
- Install it with `puppet module install <owner>-<name>`.
- Declare its main class, set the parameters listed on its Forge page, and run the agent.

To go further, read [Module fundamentals](modules_fundamentals.html) to understand how modules are structured, and [Classes](lang_classes.html) to learn how to organize the classes you declare.
