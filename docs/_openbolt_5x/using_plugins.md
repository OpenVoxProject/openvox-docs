---
layout: default
title: Using plugins
---

# Using plugins

OpenBolt supports the use of plugins to dynamically load information during an OpenBolt
run and change how OpenBolt executes certain actions. OpenBolt ships with some plugins,
but you can also create your own plugins or install plugins created by other
users.

There are three types of plugins that you can use with OpenBolt:

- **Reference plugins:** Use to fetch data from an external source and store it
  in a static data object.
- **Secret plugins:**  Use to create keys for encryption and decryption, to
  encrypt plaintext, or to decrypt ciphertext.
- **Puppet library plugins:** Use to install Puppet libraries on a target when a
  plan calls the `apply_prep` function.

## Reference plugins

Reference plugins fetch data from an external source and store it in a static
data object. You can use reference plugins to dynamically load information into
a configuration file or inventory file, or to load information for use in a
plan.

For example, you might use a reference plugin to prompt a user to enter a
password, or query AWS for a list of targets to populate the inventory with.

### Using reference plugins in configuration and inventory files

You can use reference plugins in configuration and inventory files. For example,
you can use plugins to dynamically load sensitive information or to generate
lists of targets.

To use a reference plugin in a configuration or inventory file, add an object
with a `_plugin` key where you want to use the plugin. The `_plugin` key accepts
the name of the plugin that you are using. You can also include additional keys
that correspond to the parameters that the plugin accepts.

For example, if you wanted to prompt for a password that is used to authenticate
with targets, you could use the supported `prompt` plugin in your configuration
file:

```yaml
# bolt-defaults.yaml
inventory-config:
  ssh:
    password:
      _plugin: prompt
      message: Enter SSH password
```

You can also use reference plugins to generate lists of targets in an
inventory file. For example, you can generate a list of targets from a
Terraform state file using the supported `terraform` plugin:

```yaml
# inventory.yaml
groups:
  - name: terraform
    targets:
      _plugin: terraform
      dir: /Users/bolt/terraform/project
      resource_type: aws_instance.web
      target_mapping:
        uri: public_ip
```

Whenever a plugin is used in a configuration or inventory file, it must return a
valid value for the field it is being used with. For example, because the
`targets` field of an inventory file expects an array, a plugin under the
`targets` field of an inventory file must return an array.

Reference plugins are resolved only as needed. In configuration files, all
reference plugins are resolved as as soon as OpenBolt loads the file. In inventory
files, reference plugins under the `groups` and `targets` keys are resolved as
soon as the inventory file is loaded, whereas reference plugins under data keys
such as `config` or `facts` are resolved once OpenBolt starts running an action on
that target.

While plugins are supported for configuration files, they're disabled for some settings. You can see
which options are available on configuration references pages for
[bolt-project.yaml](bolt_project_reference.html) and [bolt-defaults.yaml](bolt_defaults_reference.html).
If you'd like another setting to have plugins enabled, let us know in the
[OpenVox community](/ecosystem/latest/community.html) or by [opening an
issue](https://github.com/OpenVoxProject/openbolt/issues).

📖 **Related information**

- [Configuring OpenBolt](configuring_bolt.html)
- [Inventory files](inventory_files.html)

### Using reference plugins in plans

You can use reference plugins in plans. For example, if your plan launches new
Azure VMs, you can use a reference plugin to fetch a list of the new instances
for use in your plan.

To use a reference plugin in a plan, call the `resolve_references` plan
function. This function accepts a single argument: a hash of reference data to
resolve. The hash is identical in structure to how you would use a reference
plugin in a configuration or inventory file, and can include multiple reference
plugins. When the `resolve_references` function is called, it resolves all of
the plugin references in the hash, returning a hash of resolved data.

For example, to use the `env_var` reference plugin in a plan to retrieve a
value from an environment variable, you would call the `resolve_references`
plan function like this:

```ruby
$references = {
  "value" => {
    "_plugin" => "env_var",
    "var"     => "BOLT_PASSWORD"
  }
}

$resolved = resolve_references($references)
```

If you wanted to use the `terraform` reference plugin in a plan to generate a
list of targets from a Terraform state file, you would call the
`resolve_references` function like this:

```ruby
$references = {
  "targets" => [
    "_plugin"        => "terraform",
    "dir"            => "/Users/bolt/terraform/project",
    "resource_type"  => "aws_instance.web",
    "target_mapping" => {
      "uri" => "public_ip"
    }
  ]
}

$resolved = resolve_references($references)
```

📖 **Related information**

- [OpenBolt functions: resolve_references](plan_functions.html#resolve_references)

## Secret plugins

Use secret plugins to create keys for encryption and decryption, to encrypt
plaintext, or to decrypt ciphertext. OpenBolt uses secret plugins as part of the `bolt
secret *` commands and `*-BoltSecret` cmdlets.

By default, OpenBolt is configured to use the bundled `pkcs7` secret plugins.
However, you can specify a different secret plugin for OpenBolt to use with the
`plugin` command-line option. For example, to use an alternative secret plugin
to encrypt a plaintext value, you would run the following command:

- _\*nix shell command_

  ```shell
  bolt secret encrypt '$ecretP@$$word!' --plugin <plugin name>
  ```

- _PowerShell cmdlet_

  ```powershell
  Protect-BoltSecret -Text '$ecretP@$$word!' -Plugin <plugin name>
  ```

## Puppet library plugins

Puppet library plugins install Puppet libraries on a target when a plan calls
the `apply_prep` function. OpenBolt is configured to use the `openvox_bootstrap`
plugin, which runs the [`openvox_bootstrap::install` task](https://forge.puppet.com/modules/puppet/openvox_bootstrap), as the
default Puppet library plugin. However, you can configure OpenBolt to use
another plugin instead.

To configure OpenBolt to use a specific Puppet library plugin, configure the
`puppet_library` plugin hook under the `plugin-hooks` key in a configuration
file. The `puppet_library` plugin hook accepts one of two different plugins.
The `openvox_bootstrap` plugin is the default plugin that OpenBolt is configured to use,
while `task` can be used to specify a task to run as a plugin.

```yaml
# bolt-defaults.yaml
plugin-hooks:
  puppet_library:
    plugin: task
    task: <plugin name>
```

The following example uses the `package` task as a `puppet_library` plugin. It
installs the `openvox-agent` package with the target's package manager, without
adding the OpenVox package repository the way `openvox_bootstrap::install` does.
Use it when your targets already have a repository that provides
`openvox-agent`, such as an internal mirror.

```yaml
plugin-hooks:
  puppet_library:
    plugin: task
    task: package
    parameters:
      name: openvox-agent
      action: install
```

**NOTE**: If you are configuring plugin hooks in an inventory file, you must use `plugin_hooks`
instead of `plugin-hooks`. For more information, see the
[inventory.yaml reference](bolt_inventory_reference.html#plugin_hooks).

## Configuring plugins

Plugins that accept parameters can be configured in OpenBolt's configuration files.
Each time OpenBolt uses a plugin, it will use this configuration as default values
for the plugin.

Configure plugins when you need to use a consistent parameter value across
multiple plugin uses. For example, if a reference plugin accepts a `password`
parameter to authenticate with a service, you might want to configure the plugin
to always use the same password so you don't need to specify it each time you
use the plugin.

To configure a plugin, specify the name of the plugin under the `plugins` key of
a configuration file. Each plugin accepts a hash of parameters and values for
the parameters. For example, the following configuration file changes where the
`pkcs7` plugin looks for a private key:

```yaml
# bolt-project.yaml
plugins:
  pkcs7:
    private_key: /Users/bolt/keys/private_key.pem
```

You can also use plugins to configure other plugins. For example, you can
configure the `vault` plugin to use the `prompt` plugin to prompt for a
password:

```yaml
# bolt-project.yaml
plugins:
  vault:
    auth:
      method: userpass
      user: Developer
      password:
        _plugin: prompt
        message: Enter your Vault password
```

📖 **Related information**

- For information on how to write your own plugins, see [Writing
  plugins](writing_plugins.html).
- For a list of supported plugins that ship with OpenBolt, see [Supported
  plugins](supported_plugins.html).
- For information on how to install modules, which can include plugins, see
  [Installing modules](bolt_installing_modules.html).
- [Configuring OpenBolt](configuring_bolt.html).
