---
layout: default
title: OpenBolt 5
---

OpenBolt is a community implementation of [Puppet Bolt](https://github.com/puppetlabs/bolt) — an open
source orchestration tool that automates infrastructure management over SSH and WinRM without requiring
agents. Use OpenBolt to run commands, scripts, and tasks across remote targets, or to orchestrate
complex workflows using plans.

OpenBolt is downstream-compatible with Puppet Bolt — existing tasks, plans, modules, and inventory files work unchanged.

## How it works

OpenBolt connects directly to remote targets using SSH or WinRM, authenticates as a specified user, and
executes work on the target. There is no persistent agent or daemon: each Bolt run is a one-shot
operation that connects, executes, and disconnects.

Work is expressed at several levels:

- **Commands** — run a shell command directly on targets
- **Scripts** — upload and execute a script file on targets
- **Tasks** — self-contained, reusable units of automation with defined parameters; written in any language
- **Plans** — Puppet or YAML programs that sequence tasks, commands, and scripts across multiple targets with conditional logic

## Getting started

- [Installing OpenBolt](bolt_installing.html)
- [Getting started with Bolt](getting_started_with_bolt.html)
- [Writing tasks](writing_tasks.html)
- [Writing plans](writing_plans.html)
