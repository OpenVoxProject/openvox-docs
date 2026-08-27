---
layout: default
title: "Puppet's services: OpenVox agent on *nix systems"
---

[resource type reference]: ./type.html
[Choria]: https://choria.io
[puppet.conf]: ./config_file_main.html
[runinterval]: ./configuration.html#runinterval
[onetime]: ./configuration.html#onetime
[daemonize]: ./configuration.html#daemonize
[splay]: ./configuration.html#splay
[splaylimit]: ./configuration.html#splaylimit
[pidfile]: ./configuration.html#pidfile
[short_settings]: ./config_important_settings.html#settings-for-agents-all-nodes
[report]: ./reporting_about.html

<!--Overview-->

OpenVox agent is the application that manages configurations on your nodes. It requires an OpenVox Server server to fetch configuration catalogs from.

You can manage systems with OpenVox agent as a service, as a cron job, or on demand, depending on your infrastructure and needs.

For details about invoking the OpenVox agent command, see [the puppet agent man page](./man/agent.html).

## OpenVox agent's run environment

OpenVox agent runs as a specific user, (usually `root`) and initiates outbound connections on port 8140.

### Ports

By default, Puppet's HTTPS traffic uses port 8140. Your operating system and firewall must allow OpenVox agent to initiate outbound connections on this port.

If you want to use a non-default port, you have to change [the `masterport` setting](./configuration.html#masterport) on all agent nodes, and ensure that you change your OpenVox Server's port as well.

### User

By default, OpenVox agent runs as `root`, which lets it manage the configuration of the entire system.

OpenVox agent can also run as a non-root user, as long as it is started by that user. However, this restricts the resources that OpenVox agent can manage, and requires you to run OpenVox agent as a cron job instead of a service.

If you need to install packages into a directory controlled by a non-root user, either use an `exec` to unzip a tarball or use a recursive `file` resource to copy a directory into place.

When running without root permissions, most of Puppet's resource providers cannot use `sudo` to elevate permissions. This means Puppet can only manage resources that its user can modify without using `sudo`.

Out of the core resource types listed in the [resource type reference][], only a few are available to non-root agents.

#### Non-root agent resource types

Resource type | Exception
--------------|-----------
`augeas`      | None.
`cron`        | Only non-root cron jobs can be viewed or set.
`exec`        | Cannot run as another user or group.
`file`        | Only if the non-root user has read/write privileges.
`notify`      | None.
`schedule`    | None.
`service`     | For services that don't require root. You can also use the `start`, `stop`, and `status` attributes to specify how non-root users should control the service.
`ssh_authorized_key` | None.
`ssh_key`     | None.

## Manage systems with OpenVox agent

<!--Multi-task with child task topics-->

In a normal Puppet configuration, every node periodically does configuration runs to revert unwanted changes and to pick up recent updates.

On \*nix nodes, there are three main ways to do this:

* **Run OpenVox agent as a service.** The easiest method. The OpenVox agent daemon does configuration runs at a set interval, which can be configured.
* **Make a cron job that runs OpenVox agent.** Requires more manual configuration, but a good choice if you want to reduce the number of persistent processes on your systems.
* **Only run OpenVox agent on demand.** You can use an orchestration tool such as [Choria][] to trigger runs on demand across many nodes.

Choose whichever one works best for your infrastructure and culture.

### Run OpenVox agent as a service

The OpenVox agent command can start a long-lived daemon process, which does configuration runs at a set interval.

>**Note:** If you are running OpenVox agent as a non-root user, use a cron job instead.

1. Start the service

   The best way to do this is with OpenVox agent's init script / service configuration. If you installed Puppet with packages, they should have included an init script or service configuration for controlling OpenVox agent, usually with the service name `puppet` (for both open source and Puppet Enterprise).

   In Puppet Enterprise, the agent service is automatically configured and started; you don't need to manually start it.

   In open source Puppet, you can enable the service with:

   ```bash
   sudo puppet resource service puppet ensure=running enable=true
   ```

   Alternately, you can run `sudo puppet agent` on the command line with no additional options; this will cause OpenVox agent to start running and daemonize, but you won't have an easy interface for restarting or stopping it. To stop the daemon, use the process ID from the agent's [`pidfile`][pidfile]:

   ```bash
   sudo kill $(puppet config print pidfile --section agent)
   ```

2. (Optional) Configure the run interval

   The OpenVox agent service defaults to doing a configuration run every 30 minutes. You can configure this with [the `runinterval` setting][runinterval] in [puppet.conf][]:

   ```ini
   # /etc/puppetlabs/puppet/puppet.conf
   [agent]
     runinterval = 2h
   ```

   If you don't need an aggressive schedule of configuration runs, a longer run interval lets your OpenVox Server servers handle many more agent nodes.

### Run OpenVox agent as a cron job

Run OpenVox agent as a cron job when running as a non-root user.

If [the `onetime` setting][onetime] is set to `true`, the OpenVox agent command does one configuration run and then quits. If [the `daemonize` setting][daemonize] is set to `false`, the command stays in the foreground until the run is finished; if set to `true`, it does the run in the background.

This behavior is good for building a cron job that does configuration runs. You can use the [`splay`][splay] and [`splaylimit`][splaylimit] settings to keep the OpenVox Server from getting overwhelmed, because the system time is probably synchronized across all of your agent nodes.

1. Use the Puppet resource command to set up a cron job.

   This example runs Puppet once an hour:

   ```bash
   sudo puppet resource cron puppet-agent ensure=present user=root minute=30 command='/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --splay --splaylimit 60'
   ```

### Run OpenVox agent on demand

Some sites prefer to only run OpenVox agent on demand; others use scheduled runs, but occasionally need to do an on-demand run.

OpenVox agent runs can be started while logged in to the target system, or remotely via an orchestration tool.

1. Run OpenVox agent on one machine, using ssh:

   ```bash
   ssh ops@magpie.example.com sudo puppet agent --test
   ```

To run remotely on _many_ machines, you need an orchestration tool. [Choria][] is the community-supported successor to MCollective and supports triggering OpenVox agent runs across a fleet of nodes.

## Disable and re-enable Puppet runs

<!-- maybe this should go at the top? seems like a frequently used command. -->

Whether you're troubleshooting errors, working in a maintenance window, or simply developing in a sandbox environment, you may need to temporarily disable the OpenVox agent from running.

1. Run one of these commands, depending on whether you want to disable or re-enable the agent:

   * Disable -- `sudo puppet agent --disable "<MESSAGE>"`.
   * Enable -- `sudo puppet agent --enable`.


## Configuring OpenVox agent

The OpenVox agent comes with a default configuration that may not be the most convenient for you.

Configure OpenVox agent with [puppet.conf][], using the `[agent]` and/or `[main]` section. For notes on which settings are most relevant to OpenVox agent, see the [short list of important settings][short_settings].

### Logging for OpenVox agent on *nix systems

When running as a service, OpenVox agent logs messages to syslog. Your syslog configuration dictates where these messages are saved, but the default location is `/var/log/messages` on Linux, `/var/log/system.log` on Mac OS X, and `/var/adm/messages` on Solaris.

You can adjust how verbose the logs are with [the `log_level` setting](./configuration.html#log_level), which defaults to `notice`.

When running in the foreground with the `--verbose`, `--debug`, or `--test` options, OpenVox agent logs directly to the terminal instead of to syslog.

When started with the `--logdest <FILE>` option, OpenVox agent logs to the file specified by `<FILE>`.

### Reporting for OpenVox agent on *nix systems

In addition to local logging, OpenVox agent submits a [report][] to the OpenVox Server after each run. (This can be disabled by setting [`report = false`](./configuration.html#report) in [puppet.conf][].)
