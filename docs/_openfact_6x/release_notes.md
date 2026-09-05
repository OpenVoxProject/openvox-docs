---
layout: default
title: "OpenFact release notes"
---

This page documents the history of the OpenFact 6 series. OpenFact 6 is bundled with
`openvox-agent` 9.x; for the series bundled with the 8.x agent, see the
[OpenFact 5 release notes](/openfact/5.x/release_notes.html).

## OpenFact 6.0.0

Released on July 31, 2026

Please check the [GitHub OpenFact release page](https://github.com/OpenVoxProject/openfact/releases/tag/6.0.0) for details on new features or bug fixes.

Breaking changes in this release:

- Ruby 3.0 or later is required. Support for Ruby 2.5, 2.6, and 2.7 is dropped.
- The deprecated `ldapname` fact option and accessor are removed.
- `Facter::Core::Execution.execute` warns when called with the `time_limit` or `limit`
  option keys; use `timeout` instead.
- `Facter::Core::Execution.exec`, `Facter::Util::Resolution.exec`, and
  `Facter::Util::Resolution.which` emit runtime deprecation warnings ahead of removal in a
  future major release.
- The `Resolvable#limit` compatibility bridge for `timeout` is deprecated.
- When resolving a bare command name, OpenFact now searches `/opt/puppetlabs/bin` after
  `$PATH`, `/sbin`, and `/usr/sbin`, so facts that call the OpenVox tools work when the agent
  runs as a service without the profile.d `PATH` additions.

Other changes include Ruby 4 support and a fix for a missing `.El` macro in the `facter` man page.
