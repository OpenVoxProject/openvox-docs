---
title: "Man Page: puppet status"
---


Warning: 'puppet status' is deprecated and will be removed in a future release.

USAGE: puppet status *action* [--terminus _TERMINUS] [--extra HASH]

View puppet server status.

OPTIONS: --render-as FORMAT - The rendering format to use. --verbose - Whether to log verbosely. --debug - Whether to log debug information. --extra HASH - Extra arguments to pass to the indirection request --terminus _TERMINUS - The indirector terminus to use.

ACTIONS: find Check status of puppet master server. info Print the default terminus class for this face.

TERMINI: local, rest

See 'puppet help status' or 'man puppet-status' for full help.
