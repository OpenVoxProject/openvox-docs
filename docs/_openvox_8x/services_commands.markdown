---
layout: default
title: "Puppet's commands"
---

<!-- markdownlint-disable MD013 -->

[facter_cli]: /openfact/latest
[hiera_cli]: /openvox/latest/hiera_quick.html#testing-hiera-data-on-the-command-line
[arch]: ./architecture.html
[agent_unix]: ./services_agent_unix.html
[agent_windows]: ./services_agent_windows.html
[agent_man]: ./man/agent.html
[apply]: ./services_apply.html
[apply_man]: ./man/apply.html
[puppet forge]: https://forge.puppetlabs.com
[module fundamentals]: ./modules_fundamentals.html
[installing modules]: ./modules_installing.html
[publishing modules on the puppet forge]: ./modules_publishing.html
[module_man]: ./man/module.html
[resource_man]: ./man/resource.html
[about puppet's settings]: ./config_about_settings.html
[checking values of settings]: ./config_print.html
[editing settings on the command line]: ./config_set.html
[short list of important settings]: ./config_important_settings.html
[config_man]: ./man/config.html
[parser_man]: ./man/parser.html
[help_man]: ./man/help.html
[all_manpages]: ./man/overview.html
[about_server]: /openvox-server/latest/services_puppetserver.html
[subcommands]: /openvox-server/latest/subcommands.html

Puppet's command line interface consists of a single `puppet` command with many subcommands.

[Puppet Server][about_server] and Puppet's companion utilities, [Facter][facter_cli] and [Hiera][hiera_cli], have their own command line interfaces, which differ slightly from Puppet's.

## Core services

The following subcommands are the main applications Puppet uses to manage systems. Every user should understand what they do.

### OpenVox agent

OpenVox agent manages systems, with the help of an OpenVox Server. It requests a configuration catalog from an OpenVox Server server, then ensures that all resources in that catalog are in their desired state.

For more information, see:

* [Overview of Puppet's Architecture][arch]
* [Puppet Agent on \*nix Systems][agent_unix]
* [Puppet Agent on Windows Systems][agent_windows]
* [Puppet Agent's Man Page][agent_man]

### Puppet Server

Puppet Server compiles configurations for any number of OpenVox agents, using Puppet code and various other data sources. It provides the same services as the classic OpenVox Server application, and more.

Puppet Server has its own subcommand, `puppetserver`, which isn't prefaced by the usual `puppet` subcommand.

For more information, see:

* [Overview of Puppet's Architecture][arch]
* [Puppet Server][about_server]
* [Puppet Server Subcommands][subcommands]

### Puppet apply

Puppet apply manages systems without needing to contact an OpenVox Server server. It compiles its own configuration catalog, using Puppet modules and various other data sources, then immediately applies the catalog.

For more information, see:

* [Overview of Puppet's architecture][arch]
* [Puppet Apply][apply]
* [Puppet Apply's Man Page][apply_man]

## Administrative tools

### Puppet module

Puppet module is a multi-purpose tool for working with Puppet modules. It can install and upgrade new modules from the [Puppet Forge][], help generate new modules, and package modules for public release.

For more information, see:

* [Module Fundamentals][]
* [Installing Modules][]
* [Publishing Modules on the Puppet Forge][]
* [Puppet Module's Man Page][module_man]

### Puppet resource

Puppet resource lets you interactively inspect and manipulate resources on a system. It can work with any resource type Puppet knows about.

For more information, see:

* [Puppet Resource's Man Page][resource_man]

### Puppet config

Puppet config lets you view and change Puppet's settings.

For more information, see:

* [About Puppet's Settings][]
* [Checking Values of Settings][]
* [Editing Settings on the Command Line][]
* [Short List of Important Settings][]
* [Puppet Config's Man Page][config_man]

## Accessories

### Puppet parser

Puppet parser lets you validate Puppet code to make sure it contains no syntax errors. It can be a useful part of your continuous integration toolchain.

For more information, see:

* [Puppet Parser's Man Page][parser_man]

### Puppet help and Puppet man

Puppet help and Puppet man can display online help for Puppet's other subcommands.

For more information, see:

* [Puppet Help's Man Page][help_man]

## Full list of subcommands

Puppet has other subcommands, most of which aren't as generally useful as the ones listed above. For a complete list, see:

* [List of Puppet's subcommands][all_manpages]
