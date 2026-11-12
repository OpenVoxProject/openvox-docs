---
layout: default
title: OpenBolt projects
---

# OpenBolt projects

An OpenBolt project is a simple directory that serves as the launching point for
OpenBolt. You store your inventory file and configuration files in a project,
together with your OpenBolt content such as plans and tasks.

In addition to working with your local OpenBolt content, OpenBolt projects give you a
way to share that content with other users in your organization. You can create
orchestration that is specific to the infrastructure you're working with, and
then commit the project directory to version control for others to consume.

OpenBolt identifies a directory as an OpenBolt project as long as a `bolt-project.yaml`
file exists at the root of the directory, and the `bolt-project.yaml` file
contains a `name` key.

## Create an OpenBolt project

To create an OpenBolt project:

1. Create a directory for your OpenBolt project. To avoid having to specify a
   project name in the next step, follow project naming conventions. Project
   names can contain only lowercase letters, numbers, and underscores, and begin
   with a lowercase letter.
2. Run `bolt project init` (or `New-BoltProject` for PowerShell cmdlet).
   OpenBolt creates a `bolt-project.yaml` file in your project directory.
   At this point, the `bolt-project.yaml` only contains a `name` key with the
   name of your project.

Congratulations, you've created an OpenBolt project! 🎉 Develop your plans and
tasks in `plans` and `tasks` directories in the root of the project directory,
next to `bolt-project.yaml`. OpenBolt loads tasks and plans from the `tasks` and
`plans` directories and namespaces them to the project name.

Here is an example of a typical project with a task, a plan, and an inventory
file:

```console
.
├── bolt-project.yaml
├── inventory.yaml
├── plans
│   └── myplan.yaml
└── tasks
    ├── mytask.json
    └── mytask.py
```

> 🔩 **Tip:** To create a project with a list of pre-installed modules, use the
> `--modules` option. For more information, see
> [](./bolt_installing_modules.html#create-an-openbolt-project-with-pre-installed-modules).

## Configuring a project

Besides the `name` key, the `bolt-project.yaml` file holds options to configure
your OpenBolt project, as well as options to control how OpenBolt behaves when you run a
project.

For example, if you want to add a little flair to your OpenBolt output, use the
`rainbow` output format:

```yaml
# bolt-project.yaml
name: myproject
format: rainbow
```

For a list of all the available project configuration options, see
[`bolt-project.yaml` options](bolt_project_reference.html).

### Limiting displayed plans and tasks

Projects allow you to limit which plans and tasks a user can see when running
`bolt plan|task show` and `Get-Bolt(Plan|Task)`.

Limiting tasks and plans is useful for the following reasons:

- OpenBolt is bundled with several plans and tasks that might not be useful in your
  project.
- You might have written a task or plan that is only used by another task or
  plan, and you don't want your users to run that task or plan directly.
- Displaying only specific content in the UI makes it easier for your users to
  find what they're looking for.

To control which plans and tasks appear when your users show project content,
add `plans` and `tasks` keys to your `bolt-project.yaml`. Both keys accept a list
of names and glob patterns to filter content by.

For example, to surface a plan named `myproject::myplan`, and a task named
`myproject::mytask`, you would use the following `bolt-project.yaml` file:

```yaml
name: myproject
plans:
- myproject::myplan
tasks:
- myproject::mytask
```

If your user runs the `bolt plan show` command or `Get-BoltPlan` PowerShell
cmdlet, they'll get similar output to this:

```console
$ bolt plan show
myproject::myplan

MODULEPATH:
/PATH/TO/BOLT_PROJECT/.modules

Use `bolt plan show <plan-name>` to view details and parameters for a specific plan.
```

You can also use glob patterns to match multiple plan or task names. For
example, to surface all tasks and plans in a project named `myproject`, you
would use the following `bolt-project.yaml` file:

```yaml
name: myproject
plans:
- myproject::*
tasks:
- myproject::*
```

Glob patterns that begin with a metacharacter might cause problems when the
configuration file is loaded and parsed, because the pattern might not be
recognized as a string. To avoid this parsing issue, wrap any glob pattern that
begins with a metacharacter in quotes. For example, you would write
`"[abc]_module::*"` instead of `[abc]_module::*`.

The following metacharacters can be used in a glob pattern:

| Metacharacter | Description |
| --- | --- |
| `*` | Matches any number of characters. |
| `?` | Matches any one character. |
| `[set]` | Matches any one character in the set. |
| `{a,b}` | Matches pattern a and pattern b. |

## Common files and directories in a project

The following are common files and directories found in an OpenBolt project.  

|Directory/File|Description|
|---------|-----------|
|[`bolt-project.yaml`](bolt_project_reference.html)|Contains configuration options for OpenBolt and  OpenBolt projects. This file must exist for OpenBolt to find any of the other files or directories in this list.|
|[`inventory.yaml`](inventory_files.html)|Contains a list of known targets and target specific data.|
|[`plans/`](plans.html)|A directory for storing your plans.|
|[`tasks/`](tasks.html)|A directory for storing your tasks.|
|`files/`|A directory for storing content consumed by your tasks and plans, such as scripts.|
|[`Puppetfile`](bolt_installing_modules.html#)|Specifies the modules installed in your project. OpenBolt manages this file. Avoid editing it.|
|[`modules/`](bolt_installing_modules.html#)|A directory for storing your custom modules.|
|[`manifests`](applying_manifest_blocks.html)|A directory for storing your Puppet code files, known as _manifests_.|
|`hiera.yaml`|Contains the Hiera config to use for target-specific data when using `apply`.|
|`data/`|The standard path to store static Hiera data files.|
|`bolt-debug.log`|Contains debug log output for the most recent OpenBolt command.|
| `.modules/` |The directory where OpenBolt installs modules. Avoid committing this directory to source control.|

> **Remember:** A directory must have a `bolt-project.yaml` file before OpenBolt
> recognizes it as an OpenBolt project.

📖 **Related information**

- [Modules overview](modules.html)

## How OpenBolt chooses a project directory

Most of the time, you run OpenBolt commands from within an OpenBolt project directory
that you've created. Running OpenBolt from inside your project allows OpenBolt to find
your inventory and other configuration files.

However, OpenBolt always runs in the context of a project. If you don't run from
within your own OpenBolt project, or you don't specify a project, OpenBolt uses the
default project directory at `~/.puppetlabs/bolt/`.

OpenBolt uses the following methods, in order, to choose an OpenBolt directory.

1. **Environment variable:** You can specify a path to a project using the
   `BOLT_PROJECT` environment variable.
2. **Command-line specification:** You can specify a directory path on the
   command line with `--project <DIRECTORY_PATH>`. There is not an equivalent
   configuration setting because the OpenBolt directory must be known in order to
   load configuration.
3. **Parent directory:** OpenBolt traverses parents of the current directory until
   it finds one of the following:
   - A `bolt-project.yaml` file.
   - A directory named `Boltdir`.
4. **Default project directory:** If OpenBolt reaches the root of the file system
   without finding a `Boltdir` directory or `bolt-project.yaml` file, OpenBolt uses
   `~/.puppetlabs/bolt/` as the project directory.

For information on `Boltdir` directories, see [Embedded project directories](#embedded-project-directories).

## Embedded project directories

If you need to embed your OpenBolt management code into another repo, you can use an
embedded project directory. For example, you can store OpenBolt management code in
the same repo as the application that OpenBolt manages. This prevents file clutter in the
top level of the repo and allows you to run OpenBolt from anywhere in the
application's directory structure.

To create an embedded project directory, create a subdirectory in your
application's repo and name it `Boltdir`. OpenBolt treats a directory containing a
subdirectory named `Boltdir` as an embedded project directory.

The contents the `Boltdir` directory follows the same pattern as a local project
directory. As long as your `bolt-project.yaml` file contains a `name` field,
OpenBolt loads your local OpenBolt content from the top level of the `Boltdir`. Your
`Boltdir` can also contain modules.

An embedded OpenBolt directory looks like this:

```console
project/
├── Boltdir
│   ├── bolt-project.yaml
│   ├── inventory.yaml
│   ├── plans
│   │   ├── deploy.pp
│   │   └── diagnose.pp
│   └── tasks
│       ├── init.json
│       └── init.py
├── src #non-OpenBolt source code for the project
└── tests #non-OpenBolt tests for the project
```

In this example, you could run an OpenBolt command from the parent `project`
directory, and OpenBolt would still find your OpenBolt project.

> 🔩 **Tip:** You can use an existing Puppet control
  repo as an OpenBolt directory
  by adding a `bolt-project.yaml` file to it and configuring the `modulepath` to
  match the `modulepath` in `environment.conf`.

## Using modules in an OpenBolt project

OpenBolt projects make it easier for you to get started with OpenBolt without following
Puppet's module structure. However, if you're developing a custom module, you
can still use the Puppet module directory structure with OpenBolt. For more
information, see [Module structure](module_structure.html).

> **Note:** When you're naming your modules or OpenBolt project, keep in mind that
> projects take precedence over installed modules of the same name.

## World-writable project directories

On **Unix-like systems**, OpenBolt will not load a project from a world-writable
directory by default, as loading from a world-writable directory presents a
potential security risk. If you attempt to load a project from a
world-writable directory, OpenBolt does not load any content and raises an
exception.

If you wish to override this behavior and force OpenBolt to load a project from a
world-writable directory, you can set the `BOLT_PROJECT` environment variable
to the project directory path.

For example, if you wanted to load a project named `my_project` from the
world-writable directory at `~/project/`, you would set the `BOLT_PROJECT`
environment variable as:

```bash
export BOLT_PROJECT='~/project/my_project'
```

> **Note:** Exported environment variables expire at the end of the current
> session. If you need a more permanent solution, add the `export` line to your
> `~/.bashrc` or the relevant profile for the shell you're using.

If you want to use a world-writable directory for a single OpenBolt execution, set the
environment variable before the OpenBolt command:

```bash
BOLT_PROJECT='~/project/my_project' bolt command run uptime -t target1
```

> **Note:** The `BOLT_PROJECT` environment variable takes precedence over the
> `--project` CLI option.

## Migrate an OpenBolt project

After upgrading to a newer version of OpenBolt, you might find that an OpenBolt project
you created in the past no longer works as expected. Or there might be new
features that you want to use in an existing project. The `migrate` command
allows you to update old OpenBolt projects so that you can use them with the latest
OpenBolt release.

Currently, the `migrate` command:

- Updates inventory files from version 1.
- Updates projects to use `bolt-project.yaml` and `inventory.yaml` instead of `bolt.yaml`.
- Updates projects to use module dependency management.

To migrate a project:

_\*nix shell command:_

```console
bolt project migrate
```

_PowerShell cmdlet:_

```powershell
Update-BoltProject
```

The migrate command modifies files in your project and does not preserve
comments or formatting. Before using the command, **make sure to use source
control or backup your projects**.

### How OpenBolt updates inventory files

OpenBolt locates the inventory file for the current OpenBolt project and migrates it
in place.

The updates change the following keys in your inventory file:

- `nodes` becomes `targets`.
- The `name` key in a `Target` object becomes a `uri` key.

For example, the following inventory file from Bolt version 1:

```yaml
groups:
  - name: linux
    nodes:
      - name: target1.example.com
        alias: target1
      - name: target2.example.com
        alias: target2
```

Becomes:

```yaml
groups:
  - name: linux
    targets:
      - uri: target1.example.com
        alias: target1
      - uri: target2.example.com
        alias: target2
```

### How OpenBolt updates project configuration

OpenBolt locates a `bolt.yaml` file and moves its configuration to a new `bolt-project.yaml` file
and the `inventory.yaml` file. It then deletes the `bolt.yaml` file.

Project-specific configuration is moved to the `bolt-project.yaml` file, while transport
configuration is moved to the top-level `config` key in the `inventory.yaml` file. If the
`inventory.yaml` file has an existing top-level `config` key, the transport configuration
from `bolt.yaml` is deep merged, with the configuration in `inventory.yaml` having higher
precedence.

For example, a project with the following `bolt.yaml` and `inventory.yaml` files:

```yaml
# bolt.yaml
format: json
transport: winrm
winrm:
  user: Administrator
  password: Bolt!
```

```yaml
# inventory.yaml
groups:
  - name: windows
    targets:
      - target1.example.com
      - target2.example.com
config:
  winrm:
    ssl: false
```

Becomes:

```yaml
# bolt-project.yaml
format: json
```

```yaml
# inventory.yaml
groups:
  - name: windows
    targets:
      - target1.example.com
      - target2.example.com
config:
  transport: winrm
  winrm:
    ssl: false
    user: Administrator
    password: Bolt!
```

### How OpenBolt updates projects to use module dependency management

When you run the `migrate` command, OpenBolt reads your Puppetfile and prompts you
for the direct dependencies of your project. OpenBolt adds the direct dependencies
to a `modules` key in your `bolt-project.yaml` file and resolves the
dependencies of those modules. Next, OpenBolt installs the modules and dependencies
into a `.modules` directory and generates a Puppetfile with a list of the
installed modules. OpenBolt moves any modules from your `site-modules` directory
into `modules`.

For example, given a project named `myproject` with a custom module named
`mymodule` in your `site-modules` directory, and the following Puppetfile:

```puppet
mod "puppetlabs-apache", "5.5.0"
mod "puppetlabs-apt", "7.6.0"
mod "puppetlabs-mysql", "10.7.1"
mod "puppetlabs-stdlib", "6.4.0"
mod "puppetlabs-concat", "6.2.0"
mod "puppetlabs-translate", "2.2.0"
mod "puppetlabs-resource_api", "1.1.0"
mod "puppetlabs-puppetserver_gem", "1.1.1"
```

If you ran the `migrate` command, and selected the `apache`, `apt`, and `mysql`
modules as direct dependencies of your OpenBolt project, OpenBolt would do the
following:

- Update your `bolt-project.yaml` file to add the `modules` key, together with
  the `apache`, `apt`, and `mysql` modules:

  ```yaml
  ---
  name: myproject
  modules:
  - name: puppetlabs-apache
  version_requirement: "=5.5.0"
  - name: puppetlabs-apt
  version_requirement: "=7.6.0"
  - name: puppetlabs-mysql
  version_requirement: "=10.7.1"
  ```

- Resolve your dependencies and generate a new Puppetfile:

  ```puppet
  # This Puppetfile is managed by Bolt. Do not edit.
  mod "puppetlabs-apache", "5.5.0"
  mod "puppetlabs-apt", "7.6.0"
  mod "puppetlabs-mysql", "10.7.1"
  mod "puppetlabs-stdlib", "6.4.0"
  mod "puppetlabs-concat", "6.2.0"
  mod "puppetlabs-translate", "2.2.0"
  mod "puppetlabs-resource_api", "1.1.0"
  mod "puppetlabs-puppetserver_gem", "1.1.1"
  ```

- Install the modules from the Puppetfile into the `.modules` directory.
- Remove the old managed modules from the `modules/` directory.
- Move `mymodule` from `site-modules/` to `modules/`.

📖 **Related information**

- [Modules overview](modules.html)
- [Inventory files](inventory_files.html)
