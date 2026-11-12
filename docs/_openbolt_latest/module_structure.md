---
layout: default
title: Module structure
---

# Module structure

Before OpenBolt can load content like tasks, plans, functions, classes and types,
that content must exist inside a Puppet module on the current OpenBolt project's
modulepath.

By default, the OpenBolt modulepath includes the `modules` and `.modules`
directories, as well as any project-level content in the current OpenBolt project
directory. You can create project-level content to use with OpenBolt, or create a
standalone module that you can install with OpenBolt and use as you would any other
module you downloaded from the Forge.

## Directory structure of a module

Modules have a specific directory structure outlined in the [Puppet
documentation](/openvox/latest/modules_fundamentals.html#module-structure).
However, a typical module for use with OpenBolt might contain these files and directories:

|Directory/File|Contents|
|---------|--------|
|`data`|Hiera data that can be used when applying a manifest block.|
|`files`|Static files that can be loaded by a plan or required as a dependency of a task. Prefer putting non-Ruby libraries used by a task here.|
|`functions`|Puppet language functions that can be used from a plan.|
|`hiera.yaml`|Hiera configuration for this module.|
|`lib`|Typically Ruby code, such as custom Puppet functions, types, or providers.|
|`manifests`|Classes and other Puppet code usable when applying a manifest block.|
|`metadata.json`|Typical metadata for a module describing version, operating system compatibility, and other module dependencies.|
|`plans`|Plans, which must end in the `.pp` or `.yaml` extensions.|
|`tasks`|Tasks and their metadata.|

### Where to put module content

You have two options when it comes to storing and developing module content:

- You can develop modules directly in the OpenBolt project directory inside the
  `modules` directory.
- You can develop your module content outside of a project directory and then
  add the module's directory to your project's modulepath for use with OpenBolt.
  Alternatively, you can publish the module to the Forge and install it to your
  OpenBolt project.

## Modules for projects

If you're developing a module to support a particular project, you can develop
the module directly in the OpenBolt project directory. To create a skeleton
structure for your module, run `pdk new module` inside the `modules` directory
in your project. For information on creating a new project, see [OpenBolt
projects](./projects.html).

**Note**:  To use the `pdk` command, you must [install the Puppet Development
Kit](/pdk.html)

## Standalone modules

If you want to share a module publicly, you can develop the module outside of an
OpenBolt project and publish it to the Puppet Forge. If you want to use the module
in multiple OpenBolt projects, but don't want to publish it, you [can add the
directory that contains the module to your modulepath](modules.html#modulepath).

To create a standalone module and publish it on the Forge:

1. Run `pdk new module` outside of an OpenBolt project directory.
1. Develop the module.
1. Push the module to a code repository or the Forge.

After you've published the module to the Forge, you can add it to an OpenBolt project
using the OpenBolt command line. For more information, see [Installing
modules](./bolt_installing_modules.html).

Follow these tips and best practices for managing standalone modules:

- If you're testing a standalone module inside a project, add `modules/*` to
    the project's `.gitignore` file to prevent accidentally committing the
    module.
- Wherever possible, write automated tests for the tasks and plans in your
    module. The [facts module](https://github.com/puppetlabs/puppetlabs-facts)
    on GitHub has examples of unit tests for plans and integration
    \(acceptance\) tests for tasks.
