---
layout: default
toc_levels: 1
title: "Configuring OpenFact with facter.conf"
---

The `facter.conf` file is a configuration file that allows you to cache and block fact groups, and manage how OpenFact interacts with your system. There are three sections: `facts`, `global`, `cli` and `facts-group`.
All sections are optional and can be listed in any order within the file.

When you run OpenFact from the Ruby API, only the `facts` section and limited `global` settings are loaded.

Example facter.conf file:

~~~hocon
facts : {
    blocklist : [ "file system", "EC2" ],
    ttls : [
        { "timezone" : 30 days },
    ]
}
global : {
    external-dir     : [ "path1", "path2" ],
    custom-dir       : [ "custom/path" ],
    no-exernal-facts : false,
    no-custom-facts  : false,
    no-ruby          : false
}

cli : {
    debug     : false,
    trace     : true,
    verbose   : false,
    log-level : "warn"
}
fact-groups : {
 custom-group-name : ["os.name", "networking.ip"],
}
~~~

## Location

OpenFact does not create the `facter.conf` file automatically, so you must create it manually, or use a module to manage it.
OpenFact loads the file by default from `/etc/puppetlabs/facter/facter.conf` on *nix systems and `C:\ProgramData\PuppetLabs\facter\etc\facter.conf` on Windows.
Or, you can specify a different default with the `--config` command line option:

`facter --config path/to/my/config/file/facter.conf`

### `facts`

This section of `facter.conf` contains settings that affect fact groups. A fact group is a set of individual facts that are resolved together because they all rely on the same underlying system information.
When you add a group name to the config file as a part of either of these `facts` settings, all facts in that group will be affected. Currently only built-in facts can be cached or blocked.

Settings:

* `blocklist` --- Prevents all facts within the listed groups from being resolved when OpenFact runs.
  Use the `--list-block-group` command line option to list valid groups.

* `ttls` --- Caches the key-value pairs of groups and their duration to be cached.
  Use the `--list-cache-group` command line option to list valid groups.

  * Cached facts are stored as JSON in `/opt/puppetlabs/facter/cache/cached_facts` on *nix and `C:\ProgramData\PuppetLabs\facter\cache\cached_facts` on Windows.

Caching and blocking facts is useful when OpenFact is taking a long time and slowing down your code. When a system has a lot of something - for example, mount points or disks - OpenFact can take a long time
to collect the facts from each one.
When this is a problem, you can speed up OpenFact’s collection by either blocking facts you’re uninterested in (`blocklist`), or caching ones you don’t need retrieved frequently (`ttls`).

#### Example

To see a list of valid group names, from the command line, run `facter --list-block-groups` or `facter --list-cache-groups`.
The output shows the fact group at the top level, with all facts in that group nested below.

~~~text
$ facter --list-block-groups
EC2
  - ec2_metadata
  - ec2_userdata
file system
  - mountpoints
  - filesystems
  - partitions
~~~

If you want to block any of these groups, add the group name to the `facts` section of `facter.conf`, with the `blocklist` setting.

~~~hocon
facts : {
    blocklist : [ "file system" ],
}
~~~

Here, the "file system" group has been added, so the `mountpoints`, `filesystems`, and `partitions` facts will all be prevented from loading.

Within the `blocklist` and `ttls` settings, one can specify fact names:

~~~hocon
facts : {
   blocklist : [ "disks", "memory.swap" ],
}
~~~

~~~hocon
ttls : [
   { "mountpoints" : 30 days },
   { "memory.swap" : 6 hours },
]
~~~~

### `global`

The `global` section of `facter.conf` contains settings to control how OpenFact interacts with its external elements on your system.

| Setting | Effect | Default |
| ------- | ------ | ------- |
| `external-dir` | A list of directories to search for external facts. | |
| `custom-dir` | A list of directories to search for custom facts. | |
| `no-external`* | If true, prevents OpenFact from searching for external facts. | `false` |
| `no-custom`* | If true, prevents OpenFact from searching for custom facts. | `false` |
| `no-ruby`* | If true, prevents OpenFact from loading its Ruby functionality. | `false` |

\*Not available when you run OpenFact from the Ruby API.

### `cli`

The `cli` section of `facter.conf` contains settings that affect OpenFact’s command line output. All of these settings are ignored when you run OpenFact from the Ruby API.

| Setting | Effect | Default |
| ------- | ------ | ------- |
| `debug` | If true, OpenFact outputs debug messages. | `false` |
| `trace` | If true, OpenFact prints stacktraces from errors arising in your custom facts. | `false` |
| `verbose` | If true, OpenFact outputs its most detailed messages. | `false` |
| `log-level` | Sets the minimum level of message severity that gets logged. Valid options: “none”, “fatal”, “error”, “warn”, “info”, “debug”, “trace”. | “warn” |

### `facts-groups`

If you have a need to define your own group of facts beacuse you want to manage a larger set of facts within `blocklist` or `ttls` you can make use of the `facts-groups` setting.
Please note that you can not specify external facts here. Structured facts can be provided using the dot notation.

~~~hocon
fact-groups : {
 custom-group-name : ["os.name", "networking.ip"],
}
~~~
