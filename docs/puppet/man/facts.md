---
title: "Man Page: puppet facts"
---


USAGE: puppet facts *action* [--terminus _TERMINUS] [--extra HASH]

This subcommand manages facts, which are collections of normalized system information used by Puppet. It can read facts directly from the local system (with the default `facter` terminus).

OPTIONS: --render-as FORMAT - The rendering format to use. --verbose - Whether to log verbosely. --debug - Whether to log debug information. --extra HASH - Extra arguments to pass to the indirection request --terminus _TERMINUS - The indirector terminus to use.

ACTIONS: find Retrieve a node's facts. info Print the default terminus class for this face. save API only: create or overwrite an object. show Retrieve current node's facts. upload Upload local facts to the puppet master.

TERMINI: facter, json, memory, network_device, rest, store_configs, yaml

See 'puppet help facts' or 'man puppet-facts' for full help.
