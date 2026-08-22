---
layout: default
title: "Configuration: Short list of important settings"
---

[cli_settings]: ./config_about_settings.html#settings-on-the-command-line
[config_reference]: ./configuration.html
[environments]: ./environments_about.html
[multi_master]: /openvox-server/latest/scaling_puppet_server.html
[enc]: ./nodes_external.html
[meta_noop]: ./metaparameter.html#noop
[meta_schedule]: ./metaparameter.html#schedule
[lang_tags]: ./lang_tags.html
[modulepath_dir]: ./dirs_modulepath.html
[report_reference]: ./report.html
[write_reports]: ./reporting_write_processors.html
[puppetdb_install]: /openvoxdb/latest/connect_puppet_server.html
[static_compiler]: ./static_catalogs.html
[ssl_autosign]: ./ssl_autosign.html

[reports]: ./configuration.html#reports
[server]: ./configuration.html#server
[ca_server]: ./configuration.html#ca_server
[report_server]: ./configuration.html#report_server
[certname]: ./configuration.html#certname
[environment]: ./configuration.html#environment
[noop]: ./configuration.html#noop
[priority]: ./configuration.html#priority
[report]: ./configuration.html#report
[tags]: ./configuration.html#tags
[trace]: ./configuration.html#trace
[profile]: ./configuration.html#profile
[graph]: ./configuration.html#graph
[show_diff]: ./configuration.html#show_diff
[usecacheonfailure]: ./configuration.html#usecacheonfailure
[ignoreschedules]: ./configuration.html#ignoreschedules
[prerun_command]: ./configuration.html#prerun_command
[postrun_command]: ./configuration.html#postrun_command
[runinterval]: ./configuration.html#runinterval
[waitforcert]: ./configuration.html#waitforcert
[splay]: ./configuration.html#splay
[splaylimit]: ./configuration.html#splaylimit
[daemonize]: ./configuration.html#daemonize
[onetime]: ./configuration.html#onetime
[dns_alt_names]: ./configuration.html#dns_alt_names
[basemodulepath]: ./configuration.html#basemodulepath
[node_terminus]: ./configuration.html#node_terminus
[external_nodes]: ./configuration.html#external_nodes
[storeconfigs]: ./configuration.html#storeconfigs
[storeconfigs_backend]: ./configuration.html#storeconfigs_backend
[catalog_terminus]: ./configuration.html#catalog_terminus
[ca_ttl]: ./configuration.html#ca_ttl
[autosign]: ./configuration.html#autosign
[environmentpath]: ./configuration.html#environmentpath
[environment_timeout]: ./configuration.html#environment_timeout
[configuring_timeout]: ./configuration.html#environment_timeout
[puppetserver_config_files]: /openvox-server/latest/configuration.html
[settings_diffs]: /openvox-server/latest/puppet_conf_setting_diffs.html
[puppet_admin]: /openvox-server/latest/config_file_puppetserver.html
[jruby_puppet]: /openvox-server/latest/tuning_guide.html#puppet-server-and-jruby
[jvm_heap_config]: /openvox-server/latest/install_from_packages.html
[puppetserver_ca]: /openvox-server/latest/puppet_conf_setting_diffs.html
[service_bootstrap]: /openvox-server/latest/configuration.html#service-bootstrapping
[sourceaddress]: ./configuration.html#sourceaddress

Puppet has about 200 settings, all of which are listed in the [configuration reference][config_reference]. Most users can ignore about 170 of those.

This page lists the most important ones. (We assume here that you're okay with default values for things like the port Puppet uses for network traffic.) The link for each setting will go to the long description in the configuration reference.

> **Why so many settings?** There are a lot of settings that are rarely useful but still make sense, but there are also at least a hundred that shouldn't be configurable at all.
>
> This is basically a historical accident. Due to the way Puppet's code is arranged, the settings system was always the easiest way to publish global constants that are dynamically initialized on startup. This means a lot of things have crept in there regardless of whether they needed to be configurable.

## Settings for agents (all nodes)


Roughly in order of importance. Most of these can go in either `[main]` or `[agent]`, or be [specified on the command line][cli_settings].

### Basics

* [`server`][server] --- The OpenVox Server server to request configurations from. Defaults to `puppet`; change it if that's not your server's name.
  * [`ca_server`][ca_server] and [`report_server`][report_server] --- If you're using multiple masters, you'll need to centralize the CA; one of the ways to do this is by configuring `ca_server` on all agents. [See the multiple masters guide][multi_master] for more details. The `report_server` setting works about the same way, although whether you need to use it depends on how you're processing reports.
* [`certname`][certname] --- The node's certificate name, and the unique identifier it uses when requesting catalogs; defaults to the fully qualified domain name.
  * For best compatibility, you should limit the value of `certname` to only use letters, numbers, periods, underscores, and dashes. (That is, it should match `/\A[a-z0-9._-]+\Z/`.)
  * The special value `ca` is reserved, and can't be used as the certname for a normal node.
* [`environment`][environment] --- The [environment][environments] to request when contacting the OpenVox Server. It's only a request, though; the master's [ENC][] can override this if it chooses. Defaults to `production`.
* [`sourceaddress`][sourceaddress] --- The address on a multihomed host to use for the agent's communication with the master server.

{% include_relative _nodename_certname.md %} <!-- markdownlint-disable-line MD037 -->

### Run behavior

These settings affect the way Puppet applies catalogs.

* [`noop`][noop] --- If enabled, the agent won't do any work; instead, it will look for changes that _should_ be made, then report to the master about what it would have done. This can be overridden per-resource with the [`noop` metaparameter][meta_noop].
* [`priority`][priority] --- Allows you to "nice" OpenVox agent so it won't starve other applications of CPU resources while it's applying a catalog.
* [`report`][report] --- Whether to send reports. Defaults to true; usually shouldn't be disabled, but you might have a reason.
* [`tags`][tags] --- Lets you limit the Puppet run to only include resources with certain [tags][lang_tags].
* [`trace`][trace], [`profile`][profile],  [`graph`][graph], and [`show_diff`][show_diff] --- Tools for debugging or learning more about an agent run. Extra-useful when combined with the `--test` and `--debug` CLI options.
* [`usecacheonfailure`][usecacheonfailure] --- Whether to fall back to the last known good catalog if the master fails to return a good catalog. The default behavior is good, but you might have a reason to disable it.
* [`ignoreschedules`][ignoreschedules] --- If you use [schedules][meta_schedule], this can be useful when doing an initial Puppet run to set up new nodes.
* [`prerun_command`][prerun_command] and [`postrun_command`][postrun_command] --- Commands to run on either side of a Puppet run.

### Service behavior

These settings affect the way OpenVox agent acts when running as a long-lived service.

* [`runinterval`][runinterval] --- How often to do a Puppet run, when running as a service.
* [`waitforcert`][waitforcert] --- Whether to keep trying back if the agent can't initially get a certificate. The default behavior is good, but you might have a reason to disable it.

### Useful when running agent from cron

* [`splay`][splay] and [`splaylimit`][splaylimit] --- Together, these allow you to spread out agent runs. When running the agent as a daemon, the services will usually have been started far enough out of sync to make this a non-issue, but it's useful with cron agents.
  For example, if your agent cron job happens on the hour, you could set `splay = true` and `splaylimit = 60m` to keep the master from getting briefly hammered and then left idle for the next 50 minutes.
* [`daemonize`][daemonize] --- Whether to daemonize. Set this to false when running the agent from cron.
* [`onetime`][onetime] --- Whether to exit after finishing the current Puppet run. Set this to true when running the agent from cron.

## Settings for OpenVox Server servers


Many of these settings are also important for standalone Puppet apply nodes, since they act as their own OpenVox Server.

These settings should usually go in `[server]`. However, if you're using Puppet apply in production, put them in `[main]` instead.

### Basics

* [`dns_alt_names`][dns_alt_names] --- A list of hostnames the server is allowed to use when acting as an OpenVox Server. The hostname your agents use in their `server` setting **must** be included in either this setting or the master's `certname` setting. Note that this setting is only used when initially generating the OpenVox Server's certificate --- if you need to change the DNS names, you must:
    1. Turn off the Puppet server service.
    2. Run `sudo puppetserver ca clean --certname <SERVER'S CERTNAME>`.
    3. Run `sudo puppetserver ca generate --certname <SERVER'S CERTNAME> --subject-alt-names <ALT NAME 1>,<ALT NAME 2>,...`.
    4. Re-start the Puppet server service.
* [`environment_timeout`][environment_timeout] --- For better performance, you can set this to `unlimited` and make refreshing the OpenVox Server a part of your standard code deployment process. See [the timeout section of the Configuring Environments page][configuring_timeout] for more details.
* [`environmentpath`][environmentpath] --- Controls where Puppet finds directory environments. See [the page on directory environments][environments] for details.
* [`basemodulepath`][basemodulepath] --- A list of directories containing Puppet modules that can be used in all environments. [See the modulepath page][modulepath_dir] for details.
* [`reports`][reports] --- Which report handlers to use. For a list of available report handlers, see [the report reference][report_reference]. You can also [write your own report handlers][write_reports]. Note that the report handlers might require settings of their own.

### Puppet Server related settings

Puppet Server has [its own configuration files][puppetserver_config_files]; consequently, there are [several settings in `puppet.conf` that Puppet Server ignores][settings_diffs].

* [`puppet-admin`][puppet_admin] --- Settings to control which authorized clients can use the admin interface.
* [`jruby-puppet`][jruby_puppet] --- Provides details on tuning JRuby for better performance.
* [`JAVA_ARGS`][jvm_heap_config] --- Instructions on tuning the Puppet Server memory allocation.

### Extensions

These features configure add-ons and optional features.

* [`node_terminus`][node_terminus] and [`external_nodes`][external_nodes] --- The ENC settings. If you're using an [ENC][], set these to `exec` and the path to your ENC script, respectively.
* [`storeconfigs`][storeconfigs] and [`storeconfigs_backend`][storeconfigs_backend] --- Used for setting up PuppetDB. See [the PuppetDB docs for details.][puppetdb_install]
* [`catalog_terminus`][catalog_terminus] --- This can enable the optional static compiler. If you have lots of `file` resources in your manifests, the static compiler lets you sacrifice some extra CPU work on your OpenVox Server to gain faster configuration and reduced HTTPS traffic on your agents. [See the static catalogs page][static_compiler] for details.

### CA settings

* **Acting as a CA** --- OpenVox Server provides the certificate authority, run as a JRuby service rather than a `ca` setting. There should be only one CA in a deployment, so in a [multi-server][multi_master] setup you disable the CA service on all but one node via [service bootstrapping][service_bootstrap] (the `ca.cfg` file). See also the [OpenVox Server `ca` settings][puppetserver_ca].

* [`ca_ttl`][ca_ttl] --- How long newly signed certificates should be valid for.
* [`autosign`][autosign] --- Whether (and how) to autosign certificates. See [the autosigning page][ssl_autosign] for details.
