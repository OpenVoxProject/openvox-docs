---
title: "Man Page: puppet config"
---


USAGE: puppet config *action* [--section SECTION_NAME]

This subcommand can inspect and modify settings from Puppet's 'puppet.conf' configuration file. For documentation about individual settings, see https://puppet.com/docs/puppet/latest/configuration.html.

OPTIONS: --render-as FORMAT - The rendering format to use. --verbose - Whether to log verbosely. --debug - Whether to log debug information. --section SECTION_NAME - The section of the configuration file to interact with.

ACTIONS: delete Delete a Puppet setting. print Examine Puppet's current settings. set Set Puppet's settings.

See 'puppet help config' or 'man puppet-config' for full help.
