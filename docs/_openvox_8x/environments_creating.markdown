---
layout: default
title: "Creating Environments"
---

[environment.conf]: ./config_file_environment.html
[modulepath]: ./dirs_modulepath.html
[manifest_dir]: ./dirs_manifest.html
[hiera.yaml]: ./hiera_config_yaml_5.html
[default_manifest]: ./configuration.html#defaultmanifest
[puppet.conf]: ./config_file_main.html
[writingenc]: ./nodes_external.html

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

   ``` bash
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

When that node requests a catalog from the OpenVox server, it will request that environment. If you are
using an ENC and it specifies an environment for that node, the ENC value will override the config file.

> **Note:** Nodes can't be assigned to unconfigured environments. If a node is assigned to an environment
> that doesn't exist, the OpenVox server will fail to compile its catalog. The one exception is if the
> default `production` environment doesn't exist — in that case, the agent will successfully retrieve an
> empty catalog.

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
