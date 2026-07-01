---
layout: default
title: Welcome to OpenBolt 5
---

OpenBolt is an open source community implementation of [Puppet Bolt](https://github.com/puppetlabs/bolt)
— an orchestration tool that automates infrastructure management over SSH and WinRM without requiring
product-specific agents. Use OpenBolt to run commands, scripts, and tasks across
remote targets, or to orchestrate complex workflows using plans.

OpenBolt is downstream-compatible with Puppet Bolt — existing tasks, plans, modules, and inventory files work unchanged.

## How it works

OpenBolt connects directly to remote targets using SSH or WinRM, authenticates as a specified user, and
executes work on the target. There is no persistent agent or daemon: each Bolt run is a one-shot
operation that connects, executes, and disconnects.

Work is expressed at several levels:

- **Commands** — run a shell command directly on targets
- **Scripts** — upload and execute a script file on targets
- **[Tasks](tasks.html)** — self-contained, reusable units of automation with defined parameters; written in any language
- **[Plans](plans.html)** — Puppet or YAML programs that sequence tasks, commands, and scripts across multiple targets with conditional logic

## Helpful OpenBolt docs links

### Install OpenBolt

- [Installing OpenBolt](bolt_installing.html) - Follow the installation instructions for your operating system: \*nix, macOS, or Windows.
### Make one-time changes to your remote targets

- [Run a command](running_bolt_commands.html#run-a-command)
- [Run a script](running_bolt_commands.html#run-a-script)
- [Upload files](running_bolt_commands.html#upload-a-file-or-directory)

### Automate your workflow with existing tasks and plans

- [Running tasks](bolt_running_tasks.html)
- [Running plans](bolt_running_plans.html)

### Create your own tasks and plans
- [Installing OpenBolt](bolt_installing.html)
- [Getting started with Bolt](getting_started_with_bolt.html)
- [Writing tasks](writing_tasks.html)
- [Writing plans](writing_plans.html)
- [Writing plans in YAML](writing_yaml_plans.html)
- [Example plans](writing_plans.html)
- [Applying manifest blocks](applying_manifest_blocks.html)

## Other useful places

### Learn the basics

- [Getting started with OpenBolt](getting_started_with_bolt.html)
- [OpenBolt examples](bolt_examples.html) - Guided examples of how OpenBolt can help you automate common tasks.

### Watch OpenBolt development

- [OpenBolt project on GitHub](https://github.com/OpenVoxProject/openbolt)

### Docs for related OpenVox products

- [OpenVox](/openvox/latest/) – open source, community-maintained implementation of Puppet
- [OpenVox Server](/openvox-server/latest/)
- [OpenVoxDB](/openvoxdb/latest/)


### Share and contribute

- [Join us on Slack](https://voxpupuli.slack.com/) - Join the #bolt channel.
- Follow us on [Bluesky](https://bsky.app/profile/voxpupuli.bsky.social/) or [Mastodon](https://fosstodon.org/@voxpupuli/)
- [Connect with the OpenVox/VoxPupuli Community](https://voxpupuli.org/connect/) 
- [OpenVox on GitHub](https://github.com/openvox/)
- [Open source projects from VoxPupuli on GitHub](https://github.com/voxpupuli/)
- [Puppet Forge](https://forge.puppet.com) - Find modules you can use, and contribute modules you've made to the community.
