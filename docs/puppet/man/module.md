---
title: "Man Page: puppet module"
---


USAGE: puppet module *action* [--environment production ] [--modulepath ]

This subcommand can find, install, and manage modules from the Puppet Forge, a repository of user-contributed Puppet code. It can also generate empty modules, and prepare locally developed modules for release on the Forge.

OPTIONS: --render-as FORMAT - The rendering format to use. --verbose - Whether to log verbosely. --debug - Whether to log debug information. --environment production - The environment in which Puppet is running. For clients, such as `puppet agent`, this determines the environment itself, which Puppet uses to find modules and much more. For servers, such as `puppet master`, this provides the default environment for nodes that Puppet knows nothing about. When defining an environment in the `[agent]` section, this refers to the environment that the agent requests from the master. The environment doesn't have to exist on the local filesystem because the agent fetches it from the master. This definition is used when running `puppet agent`. When defined in the `[user]` section, the environment refers to the path that Puppet uses to search for code and modules related to its execution. This requires the environment to exist locally on the filesystem where puppet is being executed. Puppet subcommands, including `puppet module` and `puppet apply`, use this definition. Given that the context and effects vary depending on the [config section](https://puppet.com/docs/puppet/latest/config_file_main.html#config-sections) in which the `environment` setting is defined, do not set it globally. --modulepath - The search path for modules, as a list of directories separated by the system path separator character. (The POSIX path separator is ':', and the Windows path separator is ';'.) Setting a global value for `modulepath` in puppet.conf is not allowed (but it can be overridden from the commandline). Please use directory environments instead. If you need to use something other than the default modulepath of `<ACTIVE ENVIRONMENT'S MODULES DIR>:$basemodulepath`, you can set `modulepath` in environment.conf. For more info, see [https://puppet.com/docs/puppet/latest/environments_about.html](https://puppet.com/docs/puppet/latest/environments_about.html)

ACTIONS: changes Show modified files of an installed module. install Install a module from the Puppet Forge or a release archive. list List installed modules uninstall Uninstall a puppet module. upgrade Upgrade a puppet module.

See 'puppet help module' or 'man puppet-module' for full help.
