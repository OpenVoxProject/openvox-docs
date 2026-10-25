---
layout: default
toc_levels: 1
title: "Configuring OpenFact with facter.conf"
---

The `facter.conf` file controls which facts OpenFact blocks and caches, and how it finds and loads
facts on your system. It has four sections: `facts`, `global`, `cli`, and `fact-groups`. All
sections are optional and can appear in any order.

When you run OpenFact from the Ruby API, which is how the OpenVox agent runs it, only the `facts`
section and some `global` settings are loaded.

Example facter.conf file:

~~~hocon
facts : {
    blocklist : [ "file system", "EC2" ],
    ttls : [
        { "timezone" : 30 days },
    ]
}
global : {
    external-dir      : [ "path1", "path2" ],
    custom-dir        : [ "custom/path" ],
    no-external-facts : false,
    no-custom-facts   : false,
    no-ruby           : false
}

cli : {
    debug     : false,
    trace     : true,
    verbose   : false,
    log-level : "warn"
}
fact-groups : {
    custom-group-name : [ "os.name", "networking.ip" ],
}
~~~

## Location

OpenFact does not create the `facter.conf` file, so create it yourself or manage it with a module.
By default, OpenFact reads `/etc/puppetlabs/facter/facter.conf` on Linux and Unix systems and
`C:\ProgramData\PuppetLabs\facter\etc\facter.conf` on Windows. To use a different file, pass the
`--config` command line option:

~~~console
facter --config path/to/facter.conf
~~~

## `facts`

This section controls which facts OpenFact does not resolve (`blocklist`) and which it serves from a
cache (`ttls`). Both settings work for every type of fact:

- Built-in facts: use a group name, or a fact name such as `memory.swap`. A built-in group is a
  set of facts that are resolved together because they rely on the same system information.
- Custom facts: use the fact name.
- External facts: use the name of the file that sets them, such as `datacenter.yaml`.

You can also use the name of a group you define in the [`fact-groups`](#fact-groups) section.

Settings:

- `blocklist`: OpenFact does not resolve the listed facts and groups. To list the built-in groups,
  run `facter --list-block-groups`.
- `ttls`: OpenFact caches the listed facts and groups for the given duration instead of resolving
  them on every run. To list the built-in groups, run `facter --list-cache-groups`.
  - Cached facts are stored as JSON in `/opt/puppetlabs/facter/cache/cached_facts` on Linux and
    Unix and `C:\ProgramData\PuppetLabs\facter\cache\cached_facts` on Windows.

Blocking and caching help when fact collection is slow. On a system with many mount points or
disks, for example, OpenFact can take a long time to collect the facts for each one. Block the facts
you don't use, and cache the ones you don't need refreshed on every run.

### Example: built-in fact groups

The `facter --list-block-groups` and `facter --list-cache-groups` commands print each group at the
top level, with the facts in that group nested below it:

~~~text
$ facter --list-block-groups
...
EC2
  - ec2_metadata
  - ec2_userdata
...
file system
  - mountpoints
  - filesystems
  - partitions
...
~~~

To block a group, add its name to `blocklist`:

~~~hocon
facts : {
    blocklist : [ "file system" ],
}
~~~

This blocks the `mountpoints`, `filesystems`, and `partitions` facts.

You can also list individual fact names in `blocklist` and `ttls`:

~~~hocon
facts : {
    blocklist : [ "disks", "memory.swap" ],
}
~~~

~~~hocon
facts : {
    ttls : [
        { "mountpoints" : 30 days },
        { "memory.swap" : 6 hours },
    ]
}
~~~

### Example: a slow custom fact

To see how long each fact takes to resolve, run `facter -p --timing`. The `-p` option loads the
custom facts that your modules distribute to the agent:

~~~text
$ facter -p --timing
...
fact 'update_status', took: (1.001572) seconds
...
~~~

When you block a custom fact, OpenFact does not run its code, and any facts that confine on it are
not resolved either. Suppose a module provides `update_status`, which runs the package manager and
returns `pending` or `none`, and `update_count`, which confines on `update_status` being `pending`.
Block the fact that does the work:

~~~hocon
facts : {
    blocklist : [ "update_status" ],
}
~~~

This removes both facts. Blocking only `update_count` would hide that fact but still run the
package manager on every run.

To keep the facts but run the check less often, cache the slow fact together with the facts that
depend on it. A cached value can be up to one TTL old, for example just after you install updates.

~~~hocon
facts : {
    ttls : [
        { "update_status" : 6 hours },
        { "update_count" : 6 hours },
    ]
}
~~~

OpenFact does not reuse a cached value of `false` or `nil`; it resolves the fact again on every
run. Caching therefore does not help while a fact returns `false`, for example a yes-or-no update
check on a fully patched node. A fact that returns a string or a number is cached in every state.

To manage related facts with a single entry, define them as a group in
[`fact-groups`](#fact-groups) and use the group name instead.

### Example: legacy facts

To block every legacy fact, such as `osfamily` and `architecture`, add the `legacy` group to
`blocklist`:

~~~hocon
facts : {
    blocklist : [ "legacy" ],
}
~~~

## `global`

The `global` section of `facter.conf` controls how OpenFact finds and loads facts.

| Setting | Effect | Default |
| ------- | ------ | ------- |
| `external-dir` | A list of directories to search for external facts. | |
| `custom-dir` | A list of directories to search for custom facts. | |
| `no-external-facts`* | If `true`, OpenFact does not search for external facts. | `false` |
| `no-custom-facts`* | If `true`, OpenFact does not search for custom facts. | `false` |
| `no-ruby`* | If `true`, prevents OpenFact from loading its Ruby functionality. | `false` |
| `show-legacy` | If `true`, `facter` includes legacy facts when it lists all facts. | `false` |
| `sequential` | If `false`, OpenFact resolves built-in facts in parallel instead of one at a time. | `true` |
| `force-dot-resolution` | If `true`, a custom or external fact with a dot in its name, such as `my.fact`, becomes a structured fact (`my` containing `fact`). | `false` |

\*Not available when you run OpenFact from the Ruby API.

## `cli`

The `cli` section of `facter.conf` contains settings that affect OpenFact’s command line output. All of these settings are ignored when you run OpenFact from the Ruby API.

| Setting | Effect | Default |
| ------- | ------ | ------- |
| `debug` | If true, OpenFact outputs debug messages. | `false` |
| `trace` | If true, OpenFact prints stacktraces from errors arising in your custom facts. | `false` |
| `verbose` | If true, OpenFact outputs its most detailed messages. | `false` |
| `log-level` | Sets the minimum level of message severity that gets logged. Valid options: “none”, “fatal”, “error”, “warn”, “info”, “debug”, “trace”. | “warn” |

## `fact-groups`

Use the `fact-groups` section to define your own groups of facts, then use the group names in
`blocklist` or `ttls`. A group can contain built-in and custom facts. Use dot notation for parts of
structured facts.

A group can also name an external fact, but only `blocklist` honors it: caching an external fact
through a group has no effect. To cache external facts, list their file name in `ttls` instead.

~~~hocon
fact-groups : {
    custom-group-name : [ "os.name", "networking.ip" ],
}
~~~
