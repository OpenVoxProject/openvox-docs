---
title: "Man Page: puppet key"
---


Warning: 'puppet key' is deprecated and will be removed in a future release.

USAGE: puppet key *action* [--terminus _TERMINUS] [--extra HASH]

This subcommand manages certificate private keys. Keys are created automatically by puppet agent and when certificate requests are generated with 'puppet ssl submit_request'; it should not be necessary to use this subcommand directly.

OPTIONS: --render-as FORMAT - The rendering format to use. --verbose - Whether to log verbosely. --debug - Whether to log debug information. --extra HASH - Extra arguments to pass to the indirection request --terminus _TERMINUS - The indirector terminus to use.

ACTIONS: destroy Delete an object. find Retrieve an object by name. info Print the default terminus class for this face. save API only: create or overwrite an object. search Search for an object or retrieve multiple objects.

TERMINI: file, memory

See 'puppet help key' or 'man puppet-key' for full help.
