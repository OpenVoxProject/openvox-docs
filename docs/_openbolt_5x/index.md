---
layout: default
title: OpenBolt 5
---

OpenBolt is an open source orchestration tool that automates the manual work it
takes to maintain your infrastructure. Use it for one-off changes, such as
patching systems, troubleshooting servers, or restarting services, or as part of
a larger orchestration workflow. OpenBolt runs on your workstation and connects
directly to remote targets, so you don't need to install agent software on them.

## How it works

OpenBolt usually connects to targets over SSH (the default) or WinRM, authenticates
as a specified user, and runs work on the target. Other transports cover Docker and
Podman containers, the local machine, network devices through a proxy target,
and [Choria](choria-transport.html). There is no persistent agent or daemon:
each run connects, executes, and disconnects.

Work is expressed at several levels:

- **Commands:** run a shell command directly on targets.
- **Scripts:** upload and run a script file on targets.
- **Tasks:** reusable units of automation with defined parameters, written in
  any language.
- **Plans:** Puppet language or YAML programs that combine tasks, commands, and
  scripts across multiple targets with conditional logic.

Tasks, plans, modules, and inventory files you already have work unchanged.

## Get started

- [Install OpenBolt](bolt_installing.html) on Linux, macOS, or Windows.
- Work through [Getting started with OpenBolt](getting_started_with_bolt.html),
  then try the longer [guides](bolt_examples.html).

## Make one-time changes to your targets

- [Run a command](running_bolt_commands.html#run-a-command)
- [Run a script](running_bolt_commands.html#run-a-script)
- [Upload a file or directory](running_bolt_commands.html#upload-a-file-or-directory)

## Automate your workflow with tasks and plans

- [Running tasks](bolt_running_tasks.html)
- [Running plans](bolt_running_plans.html)
- [Writing tasks](writing_tasks.html)
- [Writing plans in YAML](writing_yaml_plans.html)
- [Writing plans in the Puppet language](writing_plans.html)
- [Applying Puppet code](applying_manifest_blocks.html)

## Related documentation

- [OpenVox](/openvox/latest/index.html): the agent, server, and the Puppet
  language that manifest blocks are written in.
- [OpenVoxDB](/openvoxdb/latest/index.html): the database that the `puppetdb`
  plugin and plan functions query.
- [PDK](/pdk.html): tooling for creating and testing modules.

## Get help and contribute

- [OpenBolt on GitHub](https://github.com/OpenVoxProject/openbolt): source code,
  issues, and pull requests.
- [OpenVox community Slack](https://short.voxpupu.li/puppetcommunity_slack_signup):
  ask questions and share what you've built.
- [Vox Pupuli](https://voxpupuli.org/): the community that OpenVox grew out of,
  which maintains many of the modules you can use with OpenBolt.
- [Puppet Forge](https://forge.puppet.com): find modules with tasks and plans,
  and publish your own.
