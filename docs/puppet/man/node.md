---
title: "Man Page: puppet node"
---


USAGE: puppet node *action* [--terminus _TERMINUS] [--extra HASH]

This subcommand interacts with node objects, which are used by Puppet to build a catalog. A node object consists of the node's facts, environment, node parameters (exposed in the parser as top-scope variables), and classes.

OPTIONS: --render-as FORMAT - The rendering format to use. --verbose - Whether to log verbosely. --debug - Whether to log debug information. --extra HASH - Extra arguments to pass to the indirection request --terminus _TERMINUS - The indirector terminus to use.

ACTIONS: clean Clean up signed certs, cached facts, node objects, and reports for a node stored by the puppetmaster find Retrieve a node object. info Print the default terminus class for this face.

TERMINI: exec, json, memory, msgpack, plain, rest, store_configs, yaml

See 'puppet help node' or 'man puppet-node' for full help.
