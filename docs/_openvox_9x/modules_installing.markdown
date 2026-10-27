---
layout: default
title: "Installing modules"
---

[modulepath]: ./dirs_modulepath.html
[codedir]: ./dirs_codedir.html

[approved]: https://forge.puppet.com/approved
[supported]: https://forge.puppet.com/supported
[score]: https://forge.puppet.com


Install, upgrade, and uninstall Forge modules from the command line with the `puppet module` command.

The `puppet module` command provides an interface for managing modules from the Puppet Forge. Its interface is similar to other common package managers, such as `gem`, `apt-get`, or `yum`. You can install, upgrade, uninstall, list, and search for modules with this command.

> **Important:** If you are using a code-management tool such as r10k, do not use the `puppet module` command. With code management, you install modules with a Puppetfile; code management purges any modules that were installed with the `puppet module` command.
>
> **Solaris Note:** To use `puppet module` commands on Solaris systems, you must first install gtar.

## Using `puppet module` behind a proxy

To use the `puppet module` command behind a proxy, set the following, replacing `<PROXY IP>` and `<PROXY PORT>` with the proxy's IP address and port.

```console
export http_proxy=http://<PROXY IP>:<PROXY PORT>
export https_proxy=http://<PROXY IP>:<PROXY PORT>
```

For instance, with an HTTP proxy at 192.168.0.10 on port 8080, set:

```console
export http_proxy=http://192.168.0.10:8080
export https_proxy=http://192.168.0.10:8080
```

Alternatively, you can set these two proxy settings inside the `[user]` config section in the `puppet.conf` file: `http_proxy_host` and `http_proxy_port`. For more information, see [the configuration reference](./configuration.html#http_proxy_host).

> **Important:** Make sure to set these two proxy settings in the `user` section only. Otherwise, there can be adverse effects.

## Finding Forge modules

The Puppet Forge houses thousands of modules, which you can find by browsing the Forge on the web or by using the `puppet module search` command.

Some Forge modules are Puppet **supported** or **approved** modules.

Puppet approved modules pass our specific quality and usability requirements. We recommend these modules, but they are not supported as part of a Puppet Enterprise license agreement. Puppet supported modules have been tested with Puppet Enterprise and are fully supported.

If there are no supported or approved modules that meet your needs, evaluate available modules by module score, compatibility, documentation, last release date, and number of downloads.

> To whitelist the Forge to interact with it, the IP is 52.10.130.237. This IP is subject to change without notice.

Related topics:

* [Approved modules][approved]
* [Supported modules][supported]
* [Module score][score]

### Searching modules from the command line

The `puppet module search` command accepts a single search term and returns a list of modules whose names, descriptions, or keywords match the search term.

```console
$ puppet module search apache
Searching http://forge.puppetlabs.com ...
NAME                           DESCRIPTION            AUTHOR          KEYWORDS
puppetlabs-apache              This is a generic ...  @puppetlabs     apache web
puppetlabs-passenger           Module to manage P...  @puppetlabs     apache
DavidSchmitt-apache            Manages apache, mo...  @DavidSchmitt   apache
jamtur01-httpauth              Puppet HTTP Authen...  @jamtur01       apache
jamtur01-apachemodules         Puppet Apache Modu...  @jamtur01       apache
adobe-hadoop                   Puppet module to d...  @adobe          apache
```

When you've identified the module you want, you can then install it.

## Installing modules from the command line

The `puppet module install` command installs a module and all of its dependencies. You can install modules from the Forge, a module repository, or a release tarball.

By default, this command installs modules into the first directory in the Puppet [modulepath][], `$codedir/environments/production/modules` by default.

For example, to install the `puppetlabs-apache` module, run:

```bash
puppet module install puppetlabs-apache
```

This command accepts the following options:

Option   | Description
----------------|:---------------
`--target-dir` | Specifies a different directory for installation.
`--environment` | Installs the module into the specified environment.
`--modulepath` | Specifies a modulepath, instead of using an environment's default modulepath.
`--version` | Specifies the module version to install. You can use an exact version or a requirement string like `>=1.0.3`.
`--force` | Forcibly installs a module or re-install an existing module. Does **not** install dependencies.
`--ignore-dependencies` | Does not install any modules required by this module.
`--debug` | Displays additional information about what the `puppet module` command is doing.

> **Note: Invalid Version Warnings**
>
> If any installed module has an invalid version number (anything other than major.minor.patch), Puppet issues the following warning whenever you install a module:
>
> `Warning: module (/Users/youtheuser/.puppet/modules/module) has an invalid version number (0.1). The version has been set to 0.0.0. If you are the maintainer for this module, please update the metadata.json with a valid Semantic Version (http://semver.org).`
>
> Despite the warning, Puppet still downloads your module and does not permanently change the offending module's metadata. The version is changed only in memory during the run of the program, in order to calculate dependencies for the modules you're installing.

Related topics:

* [About the modulepath][modulepath]
* [About the codedir][codedir]

### Installing modules from the Puppet Forge

To install a module from the Puppet Forge, use the `puppet module install` command with the full name of the module you want.

The full name of a Forge module is formatted as username-modulename. For example, to instal `puppetlabs-apache`:

```bash
puppet module install puppetlabs-apache
```

### Installing from another module repository

The `puppet module` command can install modules from other repositories that mimic the Forge's interface. You can change the module repository for one installation, or you can change your default repository.

The normal default module repository is the Forge, so the default `module_repository` value is `https://forgeapi.puppetlabs.com`.

* To change the default module repository, edit the `module_repository` setting in `puppet.conf` to the base URL of the repository you want to use.

* To change the repository for a single module installation only, specify the base URL of the repository when you install the module. Use the `--module_repository` option to set this. For example:

```bash
puppet module install --module_repository http://dev-forge.example.com puppetlabs-apache
```

Related topics:

* [The `module_repository` setting](./configuration.html#module_repository)

### Installing from a release tarball

To install a module from a release tarball, specify the path to the tarball instead of the module name.

If you cannot connect to the Puppet Forge, or you are installing modules that have not yet been published to the Forge, use the `--ignore-dependencies` flag. In this case, you must manually install any dependencies.

```bash
sudo puppet module install ~/puppetlabs-apache-0.10.0.tar.gz --ignore-dependencies
```

> **Note:** You can manually install modules without the `puppet module` command. If you do, you must name your module's directory appropriately. Module directory names can only contain letters, numbers, and underscores. Dashes and periods are **not valid** and cause errors when attempting to use the module.

### Uninstalling modules

Use the `puppet module uninstall` command to remove an installed module.

You must identify the target module by its full name, in the `username-modulename` format.

By default, the command won't uninstall a module that other modules depend on or whose files have been edited since it was installed.

* To force an uninstall even if the module is a dependency or has been manually edited, use the `--force` option.
* To uninstall the module while ignoring and overwriting any local changes, use the `--ignore-changes` option.

### Upgrading modules

Use the `puppet module upgrade`command to upgrade an installed module to the latest version.

You must identify the target module by its full name, in the `username-modulename` format. The `puppet module upgrade` command has several options available:

* Use the `--version` option to specify a version.
* Use the `--ignore-changes` option to upgrade the module while ignoring and overwriting any local changes that might have been made.
* Use the `--ignore-dependencies` option to skip upgrading any modules required by this module.


## Reference: `puppet module` actions

The `puppet module` command manages modules with several actions, including install, uninstall, list, and search.

View a full description of each action with `puppet man module` or by viewing the man page online.

### `install`

Installs a module from either the Forge or a release archive.

```bash
sudo puppet module install puppetlabs-apache --version 0.0.2
```

Accepts the following options:

Option   | Description
----------------|:---------------
`--target-dir` | Specifies a different directory for installation.
`--environment` | Installs the module into the specified environment.
`--modulepath` | Specifies a modulepath, instead of using an environment's default modulepath.
`--version` | Specifies the module version to install. You can use an exact version or a requirement string like `>=1.0.3`.
`--force` | Forcibly installs a module or re-install an existing module. Does **not** install dependencies.
`--ignore-dependencies` | Does not install any modules required by this module.
`--debug` | Displays additional information about what the `puppet module` command is doing.

#### `list`

Lists installed modules.

```bash
sudo puppet module list
```

#### `search`

Searches the Forge for a module.

```bash
sudo puppet module search apache
```

#### `uninstall`

Uninstalls a Puppet module.

```bash
sudo puppet module uninstall puppetlabs-apache
```

#### `upgrade`

Upgrades a Puppet module.

```bash
sudo puppet module upgrade puppetlabs-apache --version 0.0.3
```
