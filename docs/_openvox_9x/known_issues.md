---
layout: default
toc_levels: 1234
title: "OpenVox 9 known issues"
---

As known issues are discovered in OpenVox 9 and its patch releases, they'll be added to the [project's issue tracker](https://github.com/OpenVoxProject/openvox/issues). Once a known issue is resolved, it is listed as a resolved issue in the release notes for that release, and removed from this list.

## OpenVox 9.0.0

### The agent daemon can hang while applying a catalog

A small number of users have seen the `puppet agent` daemon stop checking in, leaving a forked `puppet agent: applying configuration` process that never exits ([openvox#485](https://github.com/OpenVoxProject/openvox/issues/485)). The reports so far come from small single-vCPU Linux VMs, where it happened every few days.

The cause is a rare race between Ruby's background DNS lookup threads, which changed in Ruby 3.3 and 3.4, and the `fork` that starts each agent run. If the fork lands at the wrong moment, the child inherits a locked glibc resolver lock and every name lookup in that child blocks. OpenVox 8, which bundles Ruby 3.2, is not affected.

OpenVox 9.0.0 includes changes that make the hang much less likely and let the daemon recover on its own: the daemon no longer does name lookups right before forking a run, a run that outlives [`runtimeout`](configuration.html#runtimeout) is killed so the daemon carries on with the next run, and OpenFact bounds the FQDN lookup in its hostname resolvers.

If you still see it, setting `RUBY_TCP_NO_FAST_FALLBACK=1` in a systemd override for the `puppet` service may reduce how often it happens:

```ini
# systemctl edit puppet
[Service]
Environment=RUBY_TCP_NO_FAST_FALLBACK=1
```

Restarting the `puppet` service does not clean up a child process that is already stuck; kill it with `SIGKILL`. If you hit this on 9.0.0, add details to [openvox#485](https://github.com/OpenVoxProject/openvox/issues/485).
