---
title: "Man Page: puppet catalog"
---


USAGE: puppet catalog *action* [--terminus _TERMINUS] [--extra HASH]

This subcommand deals with catalogs, which are compiled per-node artifacts generated from a set of Puppet manifests. By default, it interacts with the compiling subsystem and compiles a catalog using the default manifest and `certname`; use the `--terminus` option to change the source of the catalog.

OPTIONS: --render-as FORMAT - The rendering format to use. --verbose - Whether to log verbosely. --debug - Whether to log debug information. --extra HASH - Extra arguments to pass to the indirection request --terminus _TERMINUS - The indirector terminus to use.

ACTIONS: apply Find and apply a catalog. compile Compile a catalog. download Download this node's catalog from the puppet master server. find Retrieve the catalog for the node from which the command is run. info Print the default terminus class for this face. save API only: create or overwrite an object. select Retrieve a catalog and filter it for resources of a given type.

TERMINI: compiler, json, msgpack, rest, store_configs, yaml

See 'puppet help catalog' or 'man puppet-catalog' for full help.
