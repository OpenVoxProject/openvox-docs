---
title: "Man Page: puppet report"
---


USAGE: puppet report *action* [--terminus _TERMINUS] [--extra HASH]

Create, display, and submit reports.

OPTIONS: --render-as FORMAT - The rendering format to use. --verbose - Whether to log verbosely. --debug - Whether to log debug information. --extra HASH - Extra arguments to pass to the indirection request --terminus _TERMINUS - The indirector terminus to use.

ACTIONS: info Print the default terminus class for this face. save API only: submit a report. submit API only: submit a report with error handling.

TERMINI: json, msgpack, processor, rest, yaml

See 'puppet help report' or 'man puppet-report' for full help.
