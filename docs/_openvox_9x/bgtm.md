---
layout: default
title: Beginner's guide to writing modules
---

[structure]: ./images/bgtmclassstructure.png

Learn how to create fantastic modules by following module best practices [standards and architecture](./style_guide.html).

Contributors to this guide have spent years creating Puppet modules, falling into every pitfall, trap, and mistake you could hope to make. This guide is intended to help you avoid our mistakes through an approachable introduction to module best practices.

Before you begin, you should be familiar with Puppet such that you have a basic understanding of the Puppet [language](./lang_summary.html), you know what constitutes a [class](./lang_classes.html), and you understand the basic module [structure](./modules_fundamentals.html).

## Giving your module purpose

Before you begin writing your module, you must define what it will do. Defining the range of your module's work helps you create concise modules that are easy to work with.

Your module should have one area of responsibility. For example, a good module addresses installing MySQL but **does not address** installing another program/service that requires MySQL.

To help plan your module appropriately, consider:

* What task do you need your module to accomplish?
* What work is your module addressing?
* What higher function should your module have within your Puppet environment?

> **Tip**: If you describe the function of your module and you find yourself using the word 'and', it's time to split the module at the 'and'.

It is standard practice for Puppet users to have 200 or more modules in an environment. Simple is better. Each module in your environment should contain related resources that enable it to accomplish a task. Create multiple modules for more complex needs. The practice of having many small, focused modules promotes code reuse and turns modules into building blocks.

As an example, let's take a look at the [`puppetlabs-puppetdb`](https://forge.puppet.com/puppetlabs/puppetdb) module. This module deals solely with the the setup, configuration, and management of PuppetDB. However, PuppetDB stores its data in a PostgreSQL database.
Rather than having the module manage PostgreSQL, the author included the [`puppetlabs-postgresql`](https://forge.puppet.com/puppetlabs/postgresql) module as a dependency, leveraging the postgresql module's classes and resources to build out the right configuration for PuppetDB.
Similarly, the `puppetdb-module` needs to manipulate the `puppet.conf` file in order to operate PuppetDB. Instead of having the `puppetdb-module` handle `puppet.conf` changes internally, the author used the [`puppetlabs-inifile`](https://forge.puppet.com/puppetlabs/inifile) module to enable `puppetlabs-puppetdb` to make only the required edits to `puppet.conf`.

## Structuring your module

The ideal module manages a single piece of software from installation through setup, configuration, and service management.

This section covers:

* [How to design your module's classes](#class-design).
* [How to develop useful parameters](#parameters).
* [How best to order your classes (rather than resources)](#ordering).
* [How to leverage and utilize dependencies](#dependencies).

To demonstrate a real-world best practices standard module, we will walk through the structure of VoxPupuli's [puppet-chrony](https://github.com/voxpupuli/puppet-chrony) module.

### Class design

A good module is comprised of small, self-contained classes that each do only one thing. Classes within a module are similar to functions in programming, using parameters to perform related steps that create a coherent whole.

In general, the best practice naming convention is that the file must be named the same as the class or definition that is contained within (with the sole exception of the [main class](#module)), and classes must be named after their function.

In terms of class structure we recommend the following (more detail below):

![module class structure][structure]

#### `module`

The main class of any module must share the name of the module and be located in the `init.pp` file. The name and location of the main module class is extremely important, as it guides the [autoloader](./lang_namespaces.html#autoloader-behavior) behavior.
The main class of a module is its interface point and ought to be the only parameterized class if possible. Limiting the parameterized classes to just the main class allows you to control usage of the entire module with the inclusion of a single class. This class should provide sensible defaults so that a user can get going with `include module`.

For instance, the main `chrony` class in the `chrony` module looks like this:

```puppet
class chrony (
  Array[Stdlib::IP::Address] $bindaddress = [],
  Array[String] $bindcmdaddress = ['127.0.0.1', '::1'],
  Optional[String] $initstepslew = undef,
  Array[String] $cmdacl = [],
  NotUndef $commandkey = 0,
  Stdlib::Unixpath $config = '/etc/chrony/chrony.conf',
  Stdlib::Filemode $config_mode = '0644',
  Boolean $config_keys_manage = true,
  Array[String[1]] $keys = [],
  Stdlib::Unixpath $driftfile = '/var/lib/chrony/drift',
 ...
```

Note that each static default is declared inline, right on the parameter, so the value is visible in the class signature and in generated reference documentation.

#### `module::install`

The install class must be located in the `install.pp` file. It should contain all of the resources related to getting the software that the module manages onto the node.

The install class must be named `module::install`, as in the `chrony` module:

```puppet
class chrony::install {
  assert_private()

  package { 'chrony':
    ensure   => $chrony::package_ensure,
    name     => $chrony::package_name,
    source   => $chrony::package_source,
    provider => $chrony::package_provider,
  }
}
```

The `install`, `config`, and `service` classes are private: they are declared only by the main `chrony` class, never directly by users. Each one calls `assert_private()`, which fails compilation with a clear message if the class is declared from outside its own module. See [public and private classes](./style_guide.html#public-and-private) for more on this distinction.

#### `module::config`

The resources related to configuring the installed software should be placed in a config class. The config class must be named `module::config` and must be located in the `config.pp` file.

For example, see the `module::config` class in the `chrony` module:

```puppet
class chrony::config {
  assert_private()

  file { $chrony::config:
    ensure  => file,
    owner   => 0,
    group   => 0,
    mode    => $chrony::config_mode,
    content => epp($chrony::config_template,
      {
        servers => chrony::server_array_to_hash($chrony::servers, ['iburst']),
        pools   => chrony::server_array_to_hash($chrony::pools, ['iburst']),
        peers   => chrony::server_array_to_hash($chrony::peers),
      }
    ),
  }
...
```

#### `module::service`

The remaining service resources, and anything else related to the running state of the software, should be contained in the service class. The service class must be named `module::service` and must be located in the `service.pp` file.

For example:

```puppet
class chrony::service {
  assert_private()

  if $chrony::service_manage {
    service { $chrony::service_name:
      ensure => $chrony::service_ensure,
      enable => $chrony::service_enable,
    }
  }

  if $chrony::wait_manage {
    service { $chrony::wait_name:
      ensure => $chrony::wait_ensure,
      enable => $chrony::wait_enable,
    }
  }
}
```

### Parameters

Parameters form the public API of your module.

They are the most important interface you expose, and you should take care to balance to the number and variety of parameters so that users can customize their interactions with the module. Below, we walk through best practices for naming and developing parameters.

#### Naming parameters

Naming consistency is imperative for community comprehension and assists in troubleshooting and collaborating on module development.

Best practices recommend the pattern of `thing_property` for naming parameters.

For example, in the `chrony` module the service resource uses `service_name`, `service_ensure`, and `service_enable`:

```puppet
class chrony::service {

  if $chrony::service_manage {
    service { $chrony::service_name:
      ensure => $chrony::service_ensure,
      enable => $chrony::service_enable,
    }
  }

}
```

If you have a parameter that toggles an entire function on and off, the naming convention can be amended to `thing_manage`. This applies, in particular, to Boolean toggles, such as when the module manages the service altogether. The `thing_manage` convention allows you to wrap all of the resources in an `if $service_manage {}` test, as shown in the `chrony` example above.

Consistent naming across modules helps with the readability and usability of your code.

#### Number of parameters

To maximize the usability of your module, make it flexible by adding parameters. Parameters enable users to customize their use of your module.

You must not hardcode data in your modules, and having more parameters is the best alternative. Hardcoding data in your module makes it inflexible, and means your module requires manifest changes to be used in even slightly different circumstances.

Avoid adding parameters that allow you to override templates. When your parameters allow  template overrides, users can override your template with a custom template that contains additional hardcoded parameters.
Hardcoded parameters in templates inhibits flexibility over time. It is far better to create more parameters and then modify the original template, or have a parameter which accepts an arbitrary chunk of text added to the template, than it is to override the template with a customized one.

For an example of a module that capitalizes on offering many parameters, please see [puppetlabs-apache](https://forge.puppet.com/puppetlabs/apache).

#### Parameter defaults

Where you put a parameter's default value depends on whether that value is the same on every supported operating system:

* **Static defaults that are identical across every supported OS** belong inline in the parameter declaration in `init.pp`.
* **OS-specific defaults** belong in module Hiera data with a per-OS hierarchy, resolved through automatic parameter lookup.

Keeping static defaults inline puts the value right where the parameter is declared, which is what module reviewers expect and what keeps the default easy to find. When defaults live only in Hiera, someone reading `init.pp` can't tell whether a parameter has a default elsewhere or must be supplied.

Inline defaults also render in generated reference documentation with any toolchain. Defaults placed only in `data/common.yaml` are invisible to upstream [puppet-strings](https://github.com/puppetlabs/puppet-strings/issues/250), though OpenVox's [openvox-strings](https://github.com/voxpupuli/openvox-strings/pull/27) can now read them.

Give each default a single home. Duplicating a value between `init.pp` and module Hiera data means two sources of truth that can drift apart.

Reserve `Optional[T] = undef` for parameters where `undef` is a genuine runtime value, such as a parameter that toggles an optional feature off. Avoid declaring a parameter `Optional` simply to defer its default to Hiera when the parameter will always receive a value, since that misleads users into thinking `undef` is a supported state.

If a parameter is genuinely required and has no sensible default, give it no default at all so that catalog compilation fails clearly when the value is missing, rather than using `Optional[T] = undef`.

For more on the mechanics of parameter defaults and Hiera data in modules, see the [Puppet language style guide](./style_guide.html#parameter-defaults).

### Ordering

Best practice is to base all order-related dependencies (such as `require` and `before`) on classes rather than resources. Class-based ordering allows you to shield the implementation details of each class from the other classes.

For example:

```puppet
    file { 'configuration':
      ensure  => present,
      require => Class['module::install'],
    }
```

Rather than making a `require` to several packages, the above ordering allows you to refactor and improve `module::install` without adjusting the manifests of other classes to match the changes.

#### Containment and anchoring

To allow other modules to form ordering relationships with your module, ensure that your main classes explicitly _contain_ any subordinate classes they declare.

Classes do not _automatically_ contain the classes they declare. This is because classes can be declared in several places via `include` and similar functions. To contain classes, use [the `contain` function](./function.html#contain). For more information and context about containment, see [the containment docs](./lang_containment.html).

For example, the `chrony` module uses containment in the main `chrony` class:

```puppet
contain chrony::install
contain chrony::config
contain chrony::service

Class['chrony::install']
-> Class['chrony::config']
~> Class['chrony::service']
```

### Dependencies

If your module's functionality depends on another module, then you must list these dependencies and include them directly.

This means you must `include x` in the main class to ensure the dependency is included in the catalog. You must also add the dependency to the module's [metadata.json](./style_guide.html#module-metadata) and `.fixtures.yml`. (`.fixtures.yml` is a file used exclusively by RSpec to pull in dependencies required to successfully run unit tests.)

## Testing your module

Ensure that the module works in a variety of conditions, and that the options and parameters of your module work together to an appropriate end result.

We recommend several testing frameworks available to help you write unit and acceptance tests. Some of these tools are already included in the Puppet Development Kit (PDK).

> **Note:** The open source version of PDK is no longer supported by Puppet. It may still be functional, but no further updates or bug fixes will be provided.

### rspec-puppet

The `rspec-puppet` gem provides a unit-testing framework for Puppet. It extends RSpec to allow the testing framework to understand Puppet catalogs, the artifact it specializes in testing. You can write tests, as in the below example, to test that aspects of your module work as intended.

```ruby
it { should contain_file('configuration') }
```

RSpec lets you provide facts, like `os['family']`, in order to test the module in various scenarios.

A typical use of RSpec is to iterate over a list of operating systems, asserting that the package and service should exist in the catalog for every operating system your module supports.

To learn more, see the [rspec-puppet documentation](https://puppetlabs.github.io/rspec-puppet/).

### puppetlabs-spec-helper

The [puppetlabs-spec-helper](https://github.com/puppetlabs/puppetlabs_spec_helper) gem automates some of the tasks required to test modules.

> **Note:** This gem is no longer needed for any Vox Pupuli modules.

This is especially useful in conjunction with `rspec-puppet`, as `puppetlabs-spec-helper` provides default Rake tasks that allow you to standardize testing across modules. It also provides some code to connect `rspec-puppet` with modules. Add it to the Gemfile of the project, and then add the following line to the Rakefile:

```ruby
require 'puppetlabs_spec_helper/rake_tasks'
```

### Beaker-rspec

[Beaker-rspec](https://github.com/voxpupuli/beaker-rspec) is an acceptance/integration testing framework.

It provisions one or more virtual machines on various hypervisors (such as [Vagrant](https://www.vagrantup.com/)) and then checks the result of applying your module in a realistic environment.

#### serverspec

[Serverspec](https://serverspec.org/) provides additional testing constructs (such as `be_running` and `be_installed`) for beaker-rspec. It allows you to abstract away details of the underlying distribution when testing. It lets you write tests like:

```ruby
describe service('httpd') do
  it { should be_running }
end
```

It then knows how to translate `be_running` into shell commands for different distributions.

## Versioning your module

Modules, like any other piece of software, must be versioned and released when changes are made. Use semantic versioning, which sets out specific rules for when to increment major and minor versions.

After you've decided on the new version number, adjust the version number in the `metadata.json` file.

This allows you to create a list of dependencies in the `metadata.json` file of your modules with specific versions of dependent modules, which ensures your module isn't used with an old dependency that won't work. Versioning also enables workflow management by allowing you to easily use different versions of modules in different environments.

## Documenting your module

We recommend that you document your module with a README explaining how your module works and a Reference section detailing information about your module's classes, defined types, functions, and resource types and providers.

For guidance, see our modules documentation [guide](./modules_documentation.html) and the [documentation](./style_guide.html#documentation) section of the OpenVox Language Style Guide.

## Releasing your module

We encourage you to publish your modules on the [Puppet Forge](https://forge.puppet.com).

Sharing your modules allows other users to write improvements to the modules you make available and contribute them back to you, effectively giving you free improvements to your modules.

Additionally, publishing your modules to the Forge helps foster community among Puppet users, and allows other Puppet community members to download and use your module.
If the Puppet community routinely releases and iterates on modules on the Forge, the quality of available modules increases dramatically and gives you access to more modules to download and modify for your own purposes. Details on how to publish modules to the Forge can be found in the [module publishing guide](./modules_publishing.html).

## Community Resources

For beginning module authors, a variety of community resources are available.

[Module basics](./modules_fundamentals.html)

[OpenVox Language Style Guide](./style_guide.html)

[The Forge](https://forge.puppet.com)

[Vox Pupuli community channels](https://voxpupuli.org/connect/)

[puppetmodule.info](https://www.puppetmodule.info) — open source Puppet module documentation server, generating fresh docs for Puppet modules and popular Git repositories
