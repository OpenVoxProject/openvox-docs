---
layout: default
title: "Configuration: Editing settings on the command line"
---

[config_sections]: ./config_file_main.html#config-sections
[puppet.conf]: ./config_file_main.html
[confdir_sys]: ./dirs_confdir.html#location

Puppet loads most of its settings from [the puppet.conf config file.][puppet.conf] You can edit this file directly, or you can change individual settings with the `puppet config set` command.

> ## When to Use This
>
> We recommend using `puppet config set` for:
>
> * Fast one-off config changes
> * Scriptable config changes in provisioning tools
>
> If you find yourself changing many settings at once, you might prefer to edit the puppet.conf file or manage it with a template.

## Usage


To assign a new value to a setting, run:

```console
sudo puppet config set <SETTING NAME> <VALUE> --section <CONFIG SECTION>
```

This will declaratively set the value of `<SETTING NAME>` to `<VALUE>` (in the specified config section). It will work the same way regardless of whether the setting already had a value.

### Config sections

The `--section` option specifies which [section of puppet.conf][config_sections] to modify. It is optional, and defaults to `main`. Valid sections are:

* `main` **(default)** --- used by all commands and services
* `master` --- used by the OpenVox Server service
* `agent` --- used by the OpenVox agent service
* `user` --- used by the Puppet apply command and most other commands

If modifying the [system config file][confdir_sys], be sure to use `sudo` or run the command as `root` or `Administrator`.

## Example


**Before:**

```ini
# /etc/puppetlabs/puppet/puppet.conf
[main]
certname = agent01.example.com
server = master.example.com
vardir = /var/opt/lib/pe-puppet

[agent]
report = true
graph = true
pluginsync = true

[server]
dns_alt_names = master,master.example.com,puppet,puppet.example.com
```

**Commands:**

```console
sudo puppet config set reports puppetdb --section server
sudo puppet config set ordering manifest
```

**After:**

```ini
# /etc/puppetlabs/puppet/puppet.conf
[main]
certname = agent01.example.com
server = master.example.com
vardir = /var/opt/lib/pe-puppet
ordering = manifest

[agent]
report = true
graph = true
pluginsync = true

[server]
dns_alt_names = master,master.example.com,puppet,puppet.example.com
reports = puppetdb
```
