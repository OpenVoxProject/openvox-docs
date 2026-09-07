---
layout: default
title: "Creating Environments"
---

[environment.conf]: ./config_file_environment.html
[modulepath]: ./dirs_modulepath.html
[manifest_dir]: ./dirs_manifest.html
[hiera.yaml]: ./hiera_config_yaml_5.html
[default_manifest]: ./configuration.html#default_manifest
[puppet.conf]: ./config_file_main.html
[writingenc]: ./nodes_external.html
[environment_setting]: ./configuration.html#environment
[strict_environment_mode]: ./configuration.html#strict_environment_mode
[use_last_environment]: ./configuration.html#use_last_environment
[lastrunfile]: ./configuration.html#lastrunfile

## Environment structure

An environment is a branch that gets turned into a directory on your OpenVox server. They follow several conventions.

When you create an environment, give it the following structure:

* It contains a `modules` directory, which becomes part of the environment's default module path.
* It contains a `manifests` directory, which will be the environment's default main manifest.
* It can optionally contain a `hiera.yaml` file.
* It can optionally contain an `environment.conf` file, which can locally override configuration settings,
  including `modulepath` and `manifest`.

> **Note:** Environment names can contain lowercase letters, numbers, and underscores. They must match the
> following regular expression: `\A[a-z0-9_]+\Z`

Related topics: [environment.conf][environment.conf]

## Environment resources

An environment specifies resources that the OpenVox server will use when compiling catalogs for agent nodes.
The `modulepath`, the main manifest, Hiera data, and the config version script can all be specified in
`environment.conf`.

### The `modulepath`

* The `modulepath` is the list of directories OpenVox will load modules from.
* By default, OpenVox will load modules first from the environment's `modules` directory, and second from the
  server's `puppet.conf` file's `basemodulepath` setting, which can be multiple directories.
* If the `modules` directory is empty or absent, OpenVox will only use modules from directories in the
  `basemodulepath`.

Related topics: [The modulepath (default config)][modulepath]

### The main manifest

* The main manifest is OpenVox's starting point for compiling a catalog.
* Unless you specify otherwise in `environment.conf`, an environment will use OpenVox's global
  `default_manifest` setting to determine its main manifest.
* The value of this setting can be an absolute path to a manifest that all environments will share, or a
  relative path to a file or directory inside each environment.
* The default value of `default_manifest` is `./manifests` — the environment's own manifests directory.
* If the file or directory specified by `default_manifest` is empty or absent, OpenVox will not fall back to
  any other manifest. Instead, it behaves as if it is using a blank main manifest.

Related topics: [main manifest][manifest_dir], [environment.conf][environment.conf],
[default_manifest setting][default_manifest], [puppet.conf][puppet.conf].

### Hiera data

Each environment can use its own Hiera hierarchy and provide its own data.

Related topics: [Hiera: Config file syntax][hiera.yaml].

### The config version script

OpenVox automatically adds a config version to every catalog it compiles, as well as to messages in reports.
The version is an arbitrary piece of data that can be used to identify catalogs and events. By default, the
config version will be the time at which the catalog was compiled (as the number of seconds since January 1,
1970).

### The environment.conf file

An environment can contain an `environment.conf` file, which can override values for certain settings:

* `modulepath`
* `manifest`
* `config_version`
* `environment_timeout`

Related topics: [environment.conf][environment.conf]

## Create an environment

Environments are turned on by default. Create an environment by adding a new directory of configuration data.

1. Inside your code directory, create a directory called `environments`.
2. Inside the `environments` directory, create a directory with the name of your new environment:
   `$codedir/environments/<ENV_NAME>`
3. Create a `modules` directory and a `manifests` directory inside the environment directory. These two
   directories will contain your Puppet code.

### Configure a modulepath

1. Set `modulepath` in the environment's `environment.conf` file. If you set a value for this setting, the
   global `modulepath` setting from `puppet.conf` will not be used by the environment.
2. Check the `modulepath` by specifying the environment when requesting the setting value:

   ```bash
   sudo puppet config print modulepath --section server --environment test
   ```

### Configure a main manifest

1. Set `manifest` in the environment's `environment.conf` file. As with the global `default_manifest`
   setting, you can specify a relative path (resolved within the environment's directory) or an absolute path.
2. To lock all environments to a single global manifest, use the `disable_per_environment_manifest` setting,
   which prevents any environment from setting its own main manifest.

### Configure a config version script

1. Specify a path to the script in the `config_version` setting in `environment.conf`. OpenVox runs this
   script when compiling a catalog for a node in the environment, and uses its output as the config version.

> **Note:** If you're using a system binary like `git rev-parse`, specify the absolute path to it. If
> `config_version` is set to a relative path, OpenVox will look for the binary in the environment, not in
> the system's PATH.

## Assign nodes to environments via an ENC

You can assign agent nodes to environments by using an external node classifier (ENC). By default, all nodes
are assigned to a default environment named `production`.

1. Ensure that the `environment` key is set in the YAML output that the ENC returns. If the `environment` key
   isn't set, the OpenVox server will use the environment requested by the agent.

> **Note:** The value from the ENC is authoritative if it exists. If the ENC doesn't specify an environment,
> the node's config value is used.

Related topics: [Writing ENCs][writingenc]

## Assign nodes to environments via the agent's config file

You can assign agent nodes to environments by editing the agent's `puppet.conf` file. By default, all nodes
are assigned to a default environment named `production`.

1. Open the agent's `puppet.conf` file in an editor.
2. Find the `environment` setting in either the `agent` or `main` section.
3. Set the value of the `environment` setting to the name of the desired environment.

Alternatively, set it from the command line:

```console
sudo puppet config set environment <ENV_NAME> --section agent
```

When that node requests a catalog from the OpenVox server, it will request that environment. If you are
using an ENC and it specifies an environment for that node, the ENC value will override the config file.

> **Note:** The environment must exist on the OpenVox server. If it doesn't, the server compiles the node's
> catalog in the server's default environment instead, and the agent keeps using that environment on later
> runs. See [How the agent chooses its environment](#how-the-agent-chooses-its-environment).

## How the agent chooses its environment

If an ENC assigns an environment to a node, that assignment is what the agent ends up applying. The server
compiles the catalog in the ENC's environment no matter which one the agent asked for, and the agent switches
to match the catalog. The only way to stop that switch is `strict_environment_mode`, which fails the run
instead. The rest of this section describes how the agent decides which environment to ask for first, which
is what matters when no ENC sets one.

On each run, the agent decides which environment to use before it requests a catalog. It uses the first of
the following that applies:

1. The `--environment` option on the command line. The agent uses this environment and skips the node request.
2. The `environment` setting from `puppet.conf`, if `strict_environment_mode` is `true`. The agent skips the
   node request and rejects any catalog compiled for a different environment.
3. The environment recorded by the previous run, if `use_last_environment` is `true`, which is the default,
   and `last_run_summary.yaml` exists. The agent records the environment it started with
   (`initial_environment`) and the one it finished with (`converged_environment`) in that file. If the two
   differ, the agent starts in the converged environment. If they match, it starts in its configured
   environment. Either way, it skips the node request.
4. The environment the server assigns in its response to the node request. The agent sends this request only
   when it has no last-run file, for example on its first run, or when `use_last_environment` is `false`. The
   answer is the ENC's value if an ENC sets one. Otherwise, the server confirms the environment the agent
   requested. If the answer differs from the agent's setting, the agent logs `Local environment: '<ENV_NAME>'
   doesn't match server specified node environment '<OTHER_ENV>', switching agent to '<OTHER_ENV>'`.
5. The `environment` setting from `puppet.conf`, or `production` if it isn't set.

The agent then requests a catalog for that environment. If the catalog comes back for a different environment,
the agent switches to it, collects facts again, and requests a new catalog. If the environment doesn't settle
after a few retries, the run fails. Because the node request is skipped whenever a last-run file exists, this
catalog check is how the server's choice reaches the agent on most runs.

### When the requested environment doesn't exist on the server

If the environment the agent requests has no directory on the server, the run doesn't fail. Instead:

1. Before syncing plugins, the agent checks that the environment exists on the server. It doesn't, so the
   agent logs `Environment '<ENV_NAME>' not found on server, skipping initial pluginsync.` and carries on
   with its configured environment. On a first run, or when `use_last_environment` is `false`, the node
   request fails first, and the agent also logs `Unable to fetch my node definition, but the agent run will
   continue` followed by `Could not find environment '<ENV_NAME>'`.
2. The catalog request doesn't require the environment to exist. The server compiles the catalog in its
   default environment, which is `production` unless the server's `puppet.conf` sets a different value, or in
   the environment an ENC assigns.
3. The agent logs `Local environment: '<ENV_NAME>' doesn't match server specified environment 'production',
   restarting agent run with environment 'production'` and applies the `production` catalog.
4. The agent writes `<ENV_NAME>` as the initial environment and `production` as the converged environment to
   `last_run_summary.yaml`.

On every later run, the agent starts in `production` and skips the node request, because
`use_last_environment` tells it to reuse the converged environment from the previous run. It stays in
`production` even after you create the missing environment on the server, until you reset it.

### Make the agent's environment authoritative

To make the agent fail its run instead of switching to a different environment, set `strict_environment_mode`
in the `agent` section:

```console
sudo puppet config set strict_environment_mode true --section agent
```

With this setting, the agent ignores the last-run file and requests a catalog for its configured
environment. If the environment doesn't exist on the server, the agent logs `Environment '<ENV_NAME>' not
found on server, aborting run.` and the run fails before it requests a catalog. If the environment exists but
the server returns a catalog for a different environment, for example because an ENC assigns one, the agent
logs `Not using catalog because its environment '<OTHER_ENV>' does not match agent specified environment
'<ENV_NAME>' and strict_environment_mode is set` and the run fails. In both cases the agent stays in its
configured environment, and the server, including any ENC, can no longer reassign it.

Strict mode also skips the node request and the last-run file, so it keeps the same optimization that
`use_last_environment` provides. Prefer it over turning `use_last_environment` off when you want the agent to
stay in its configured environment permanently.

### Reset an agent that is stuck in the wrong environment

Once the environment exists on the server again, do one of the following:

* Run the agent once with the environment on the command line:

  ```console
  sudo puppet agent -t --environment <ENV_NAME>
  ```

  A successful run records matching initial and converged environments, so later runs start in the
  configured environment again.
* Delete `last_run_summary.yaml` from the agent's public directory: `/opt/puppetlabs/puppet/public` on
  Linux and macOS, or `C:\ProgramData\PuppetLabs\puppet\public` on Windows. The next run has no last-run
  file, so the agent sends the node request and starts from its configured environment.
* Set `use_last_environment` to `false` in the `agent` section. The agent then sends the node request on
  every run and ignores the previous run's environment. This doesn't prevent the switch to `production`
  while the environment is missing, but the agent recovers as soon as the environment exists again. Treat
  this as a temporary measure. The extra node request on every run is cheap by itself, but with an ENC it
  runs the ENC twice per agent run, and if the ENC assigns a different environment than `puppet.conf` the
  agent also syncs plugins twice. Across a large fleet that adds up, which is why the setting defaults to
  `true`. For a permanent fix, use `strict_environment_mode` instead.

Related topics: [`environment`][environment_setting], [`strict_environment_mode`][strict_environment_mode],
[`use_last_environment`][use_last_environment], [`last_run_summary.yaml`][lastrunfile].

## Global settings for configuring environments

The settings in the server's `puppet.conf` file configure how OpenVox finds and uses environments.

### `environmentpath`

* `environmentpath` is the list of directories where OpenVox will look for environments. The default value
  is `$codedir/environments`.
* If you have more than one directory, separate them by colons and put them in order of precedence:
  `$codedir/temp_environments:$codedir/environments`
* If environments with the same name exist in both paths, OpenVox uses the first one it encounters.
* Put the `environmentpath` setting in the `main` section of `puppet.conf`.

### `basemodulepath`

* `basemodulepath` lists directories of global modules that all environments can access by default.
* The default includes `$codedir/modules` for user-accessible modules.
* Add additional directories of global modules by setting your own value for `basemodulepath`.

Related topics: [modulepath][modulepath].

### `default_manifest`

* `default_manifest` specifies the main manifest for any environment that doesn't set a `manifest` value in
  `environment.conf`.
* The default value is `./manifests` — the environment's own manifests directory.
* The value can be an absolute path to one manifest shared by all environments, or a relative path to a file
  or directory inside each environment's directory.

Related topics: [default_manifest setting][default_manifest].

### `disable_per_environment_manifest`

* When set to `true`, OpenVox uses the same global manifest for every environment.
* If an environment specifies a different manifest in `environment.conf`, OpenVox will not compile catalogs
  for nodes in that environment.
* If this setting is `true`, the `default_manifest` value must be an absolute path.

### `environment_timeout`

* `environment_timeout` sets how often the OpenVox server refreshes information about environments. It can
  be overridden per-environment.
* This setting defaults to `0` (caching disabled), which lowers performance but makes it easy for new users
  to deploy updated Puppet code.
* Once your code deployment process is mature, change this setting to `unlimited`.

To configure `environment_timeout`:

1. Set `environment_timeout = unlimited` in `puppet.conf`.
2. Change your code deployment process to refresh the OpenVox server whenever you deploy updated code.

> **Note:** Only use the value `0` or `unlimited`. Most OpenVox servers use a pool of Ruby interpreters,
> which all have their own cache timers. When these timers are out of sync, agents can be served inconsistent
> catalogs. To avoid that inconsistency, refresh the server when deploying.
