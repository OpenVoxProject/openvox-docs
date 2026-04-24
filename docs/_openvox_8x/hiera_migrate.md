---
layout: default
title: "Upgrading to Hiera 5"
---

[layers]: ./hiera_intro.html#hieras-three-config-layers
[backends]: ./hiera_custom_backends.html
[puppet_conf]: ./config_file_main.html
[automatic]: ./hiera_automatic.html
[legacy_backend]: ./hiera_config_yaml_5.html#configuring-a-hierarchy-level-legacy-hiera-3-backends
[v3]: ./hiera_config_yaml_3.html
[v4]: ./hiera_config_yaml_4.html
[v5]: ./hiera_config_yaml_5.html
[merging]: ./hiera_merging.html
[v5_defaults]: ./hiera_config_yaml_5.html#the-defaults-key
[v5_builtin]: ./hiera_config_yaml_5.html#configuring-a-hierarchy-level-built-in-backends
[eyaml_v5]: ./hiera_config_yaml_5.html#configuring-a-hierarchy-level-hiera-eyaml
[hash_merge_operator]: ./lang_expressions.html#merging
[class_inheritance]: ./lang_classes.html#inheritance
[conditional_logic]: ./lang_conditional.html
[custom_backend_system]: ./hiera_custom_backends.html
[functions_puppet]: ./lang_write_functions_in_puppet.html

Upgrading to Hiera 5 offers some major advantages. A real environment data layer means changes to your hierarchy are now routine and testable,
using multiple backends in your hierarchy is easier and you can make a custom backend.

> Note: If you're already a Hiera user, you can use your current code with Hiera 5 without any changes to it.
> Hiera 5 is fully backwards-compatible with Hiera 3, and legacy features will not be removed until a future major version.
> You can even start using some Hiera 5 features — like module data — without upgrading anything.

Hiera 5 uses the same built-in data formats as Hiera 3. You don't need to do mass edits of any data files.

Updating your code to take advantage of Hiera 5 features involves the following tasks:

Task | Benefit
---- | -------
Enable the environment layer, by giving each environment its own `hiera.yaml` file. | Future hierarchy changes are cheap and testable. The legacy `hiera()`, `hiera_array()`, etc. functions gain full Hiera 5 powers in any migrated environment, only if there is a `hiera.yaml` in the environment root.
Convert your global `hiera.yaml` file to the version 5 format. | You can use new Hiera 5 backends at the global layer.
Convert any experimental (version 4) `hiera.yaml` files to version 5. | Future-proof any environments or modules where you used the experimental version of Puppet lookup.
In Puppet code, replace `hiera()`/`hiera_array()`/etc. with `lookup()`. | Future-proof your Puppet code.
Use Hiera for default data in modules. | Simplify your modules with an elegant alternative to the "params.pp" pattern.

> Note: Enabling the environment layer takes the most work, but yields the biggest benefits. Focus on that first, then do the rest at your own pace.

## Use cases for upgrading to Hiera 5

- **hiera-eyaml users** — Upgrade now. OpenVox includes a built-in hiera-eyaml backend for Hiera 5. (It still requires that the `hiera-eyaml` gem be installed.)
  See the [usage instructions in the hiera.yaml (v5) syntax reference][eyaml_v5].
  This means you can move your existing encrypted YAML data into the environment layer at the same time you move your other data.

- **Custom backend users** — Wait for updated backends. You can keep using custom Hiera 3 backends with Hiera 5, but they'll make upgrading more complex,
  because you can't move legacy data to the environment layer until there's a Hiera 5 backend for it.
  If an updated version of the backend is coming out soon, wait. If you're using an off-the-shelf custom backend, check its website or contact its developer.
  If you developed your backend in-house, read the [documentation about writing Hiera 5 backends][backends].

- **Custom `data_binding_terminus` users** — Upgrade now, and replace it with a Hiera 5 backend as soon as possible.
  There's a deprecated `data_binding_terminus` setting in `puppet.conf` which changes the behavior of automatic class parameter lookup.
  It can be set to `hiera` (normal), `none` (deprecated; disables auto-lookup), or the name of a custom plugin.
  Once you have a Hiera 5 backend, integrate it into your hierarchies and delete the `data_binding_terminus` setting.

Related topics: [environment data layer][layers], [hiera.yaml (v5) eyaml usage][eyaml_v5], [writing Hiera 5 backends][backends], [puppet.conf][puppet_conf], [automatic class parameter lookup][automatic].

## Enable the environment layer for existing Hiera data

A key feature in Hiera 5 is per-environment hierarchy configuration. Because you probably store data in each environment, local `hiera.yaml` files are more logical and convenient than a single global hierarchy.

You can enable the environment layer gradually. In migrated environments, the legacy Hiera functions switch to Hiera 5 mode — they can access environment and module data without requiring any code changes.

> Note: Before migrating environment data to Hiera 5, be aware that if you rely on custom Hiera 3 backends, you should upgrade them for Hiera 5 or prepare for some extra work during migration.
> If your only custom backend is hiera-eyaml, continue upgrading — OpenVox includes a Hiera 5 eyaml backend.

The process of enabling the environment layer involves the following steps. In each environment, you will:

1. Check your code for Hiera function calls with "hierarchy override arguments", which will cause errors in Hiera 5.
   A quick way to find instances of using this argument is to search for calls with two or more commas using the following regular expression:

   ```regexp
   hiera(_array|_hash|_include)?\(([^,\)]*,){2,}[^\)]*\)
   ```

2. Choose a new data directory name. The default data directory name in Hiera 3 was `<ENVIRONMENT>/hieradata`, and the default in Hiera 5 is `<ENVIRONMENT>/data`.
   If you used the old default, use the new default.

3. Add a Hiera 5 `hiera.yaml` file to the environment. Each environment needs a Hiera config file that works with its existing data.
   See [converting a version 3 hiera.yaml to version 5](#convert-a-version-3-hierayaml-to-version-5). Make sure to reference the new `datadir` name. Save the resulting file as `<ENVIRONMENT>/hiera.yaml`.

4. If any of your data relies on custom backends that have been ported to Hiera 5, install them in the environment.
   Hiera 5 backends are distributed as OpenVox modules, so each environment can use its own version of them.

5. Move the environment's data directory by renaming it from its old name (`hieradata`) to its new name (`data`).
   If you use custom file-based Hiera 3 backends, the global layer still needs access to their data, so you need to sort the files:
   Hiera 5 data moves to the new data directory, and Hiera 3 data stays in the old data directory.

6. Repeat these steps for each environment.

7. After you have migrated the environments that have active node populations, delete the parts of your global hierarchy that you transferred into environment hierarchies.

> **Important**: The environment layer does not support Hiera 3 backends.
> If any of your data uses a custom backend that has not been ported to Hiera 5, omit those hierarchy levels from the environment config and continue to use the global layer for that data.

Related topics: [per-environment hierarchy configuration][layers], [legacy backends][legacy_backend], [hiera.yaml (v5)][eyaml_v5], [custom backends][backends].

## Convert a version 3 hiera.yaml to version 5

Hiera 5 supports three versions of the `hiera.yaml` file: version 3, version 4, and version 5. If you've been using Hiera 3, your existing configuration is a version 3 `hiera.yaml` file at the global layer.

Consider this example `hiera.yaml` version 3 file:

```yaml
:backends:
  - mongodb
  - eyaml
  - yaml
:yaml:
  :datadir: "/etc/puppetlabs/code/environments/%{environment}/hieradata"
:mongodb:
  :connections:
    :dbname: hdata
    :collection: config
    :host: localhost
:eyaml:
  :datadir: "/etc/puppetlabs/code/environments/%{environment}/hieradata"
  :pkcs7_private_key: /etc/puppetlabs/puppet/eyaml/private_key.pkcs7.pem
  :pkcs7_public_key:  /etc/puppetlabs/puppet/eyaml/public_key.pkcs7.pem
:hierarchy:
  - "nodes/%{trusted.certname}"
  - "location/%{facts.whereami}/%{facts.group}"
  - "groups/%{facts.group}"
  - "os/%{facts.os.family}"
  - "common"
:logger: console
:merge_behavior: native
:deep_merge_options: {}
```

To convert this version 3 file to version 5:

1. **Use strings instead of symbols for keys.** Remove the leading colons on keys.

2. **Remove settings that aren't used anymore.** Delete the following settings completely:
   - `:logger`
   - `:merge_behavior`
   - `:deep_merge_options`

   Paste the following settings into a temporary file for reference, then delete them from `hiera.yaml`:
   - `:backends`
   - Any backend-specific setting sections, like `:yaml` or `:mongodb`

3. **Add a `version` key** with a value of `5`:

   ```yaml
   version: 5
   hierarchy:
     # ...
   ```

4. **Set a default backend and data directory.** If you use one backend for the majority of your data, set a `defaults` key with values for `datadir` and one of the backend keys.
   The names of the backends have changed for Hiera 5:

   Hiera 3 backend | Hiera 5 backend setting
   ----------------|------------------------
   `yaml`          | `data_hash: yaml_data`
   `json`          | `data_hash: json_data`
   `eyaml`         | `lookup_key: eyaml_lookup_key`

5. **Translate the hierarchy.** In version 5, each hierarchy level has one designated backend.
   Consult the previous values for the `:backends` key and any backend-specific settings to determine how to split your existing hierarchy levels across backends.

6. **Remove hierarchy levels** that use `calling_module`, `calling_class`, and `calling_class_path`. These pseudo-variables are not supported in `hiera.yaml` version 5.

7. **Translate built-in backends** to the version 5 config:

   ```yaml
   version: 5
   defaults:
     datadir: data
     data_hash: yaml_data
   hierarchy:
     - name: "Per-node data (yaml version)"
       path: "nodes/%{trusted.certname}.yaml"

     - name: "Other YAML hierarchy levels"
       paths:
         - "location/%{facts.whereami}/%{facts.group}.yaml"
         - "groups/%{facts.group}.yaml"
         - "os/%{facts.os.family}.yaml"
         - "common.yaml"
   ```

8. **Translate hiera-eyaml backends:**

   ```yaml
   - name: "Per-group secrets"
     path: "groups/%{facts.group}.eyaml"
     lookup_key: eyaml_lookup_key
     options:
       pkcs7_private_key: /etc/puppetlabs/puppet/eyaml/private_key.pkcs7.pem
       pkcs7_public_key:  /etc/puppetlabs/puppet/eyaml/public_key.pkcs7.pem
   ```

9. **Translate custom Hiera 3 backends.** Check if the backend's author has published a Hiera 5 update.
   If there is no update, use the version 3 backend in a version 5 hierarchy at the global layer — it will not work in the environment layer.
   See [Configuring a hierarchy level (legacy Hiera 3 backends)][legacy_backend] for details.

After following these steps, the example configuration becomes:

```yaml
version: 5
defaults:
  datadir: data
  data_hash: yaml_data
hierarchy:
  - name: "Per-node data (yaml version)"
    path: "nodes/%{trusted.certname}.yaml"

  - name: "Per-node data (MongoDB version)"
    path: "nodes/%{trusted.certname}"
    hiera3_backend: mongodb
    options:
      connections:
        dbname: hdata
        collection: config
        host: localhost

  - name: "Per-group secrets"
    path: "groups/%{facts.group}.eyaml"
    lookup_key: eyaml_lookup_key
    options:
      pkcs7_private_key: /etc/puppetlabs/puppet/eyaml/private_key.pkcs7.pem
      pkcs7_public_key:  /etc/puppetlabs/puppet/eyaml/public_key.pkcs7.pem

  - name: "Other YAML hierarchy levels"
    paths:
      - "location/%{facts.whereami}/%{facts.group}.yaml"
      - "groups/%{facts.group}.yaml"
      - "os/%{facts.os.family}.yaml"
      - "common.yaml"
```

Related topics: [version 3][v3], [version 4][v4], [version 5][v5], [global layer][layers], [Merging data from multiple sources][merging], [set a defaults key][v5_defaults],
[Configuring a hierarchy level (built-in backends)][v5_builtin], [Hiera 5 backends][backends], [eyaml usage instructions][eyaml_v5].

## Convert an experimental (version 4) hiera.yaml to version 5

If you used the experimental version of Puppet lookup (Hiera 5's predecessor), you might have some version 4 `hiera.yaml` files in your environments and modules.
Hiera 5 can use these, but you will need to convert them, especially if you want to use any backends other than YAML or JSON.

Consider this example of a version 4 `hiera.yaml` file:

```yaml
# /etc/puppetlabs/code/environments/production/hiera.yaml
---
version: 4
datadir: data
hierarchy:
  - name: "Nodes"
    backend: yaml
    path: "nodes/%{trusted.certname}"

  - name: "Exported JSON nodes"
    backend: json
    paths:
      - "nodes/%{trusted.certname}"
      - "insecure_nodes/%{facts.networking.fqdn}"

  - name: "virtual/%{facts.virtual}"
    backend: yaml

  - name: "common"
    backend: yaml
```

To convert to version 5:

1. Change the value of the `version` key to `5`.

2. Add a file extension to every file path — use `"common.yaml"`, not `"common"`.

3. If any hierarchy levels are missing a `path`, add one. In version 5, `path` no longer defaults to the value of `name`.

4. If there is a top-level `datadir` key, change it to a `defaults` key and set a default backend:

   ```yaml
   defaults:
     datadir: data
     data_hash: yaml_data
   ```

5. In each hierarchy level, delete the `backend` key and replace it with a `data_hash` key:

   v4 backend      | v5 equivalent
   ----------------|--------------
   `backend: yaml` | `data_hash: yaml_data`
   `backend: json` | `data_hash: json_data`

6. Delete the `environment_data_provider` and `data_provider` settings, which enabled Puppet lookup for an environment or module.
   You'll find these in `puppet.conf`, `environment.conf`, and a module's `metadata.json`.

After being converted to version 5, the example looks like this:

```yaml
# /etc/puppetlabs/code/environments/production/hiera.yaml
---
version: 5
defaults:
  datadir: data
  data_hash: yaml_data
hierarchy:
  - name: "Nodes"
    path: "nodes/%{trusted.certname}.yaml"

  - name: "Exported JSON nodes"
    data_hash: json_data
    paths:
      - "nodes/%{trusted.certname}.json"
      - "insecure_nodes/%{facts.networking.fqdn}.json"

  - name: "Virtualization platform"
    path: "virtual/%{facts.virtual}.yaml"

  - name: "common"
    path: "common.yaml"
```

Related topics: [defaults key][v5_defaults], [the hiera.yaml version 5 reference][v5], [backends][backends].

## Convert experimental data provider functions to a Hiera 5 `data_hash` backend

Puppet lookup had experimental custom backend support, where you could set `data_provider = function` and create a function with a name that returned a hash.
You can convert such a function to a Hiera 5 `data_hash` backend:

1. Change the function's signature to accept two arguments: a `Hash` and a `Puppet::LookupContext` object. You do not have to do anything with these — just add them to the signature.

2. Delete the `data_provider` setting from the module's `metadata.json`.

3. Create a version 5 `hiera.yaml` file for the affected environment or module, and add a hierarchy level as follows:

   ```yaml
   - name: <ARBITRARY NAME>
     data_hash: <NAME OF YOUR FUNCTION>
   ```

   It does not need a `path`, `datadir`, or any other options.

## Updated classic Hiera function calls

The `hiera`, `hiera_array`, `hiera_hash`, and `hiera_include` functions are all deprecated. The `lookup` function is a complete replacement for all of these.

Hiera function                | Equivalent `lookup` call
------------------------------|-------------------------
`hiera('secure_server')`      | `lookup('secure_server')`
`hiera_array('ntp::servers')` | `lookup('ntp::servers', {merge => unique})`
`hiera_hash('users')`         | `lookup('users', {merge => hash})` or `lookup('users', {merge => deep})`
`hiera_include('classes')`    | `lookup('classes', {merge => unique}).include`

To prepare for deprecations in future OpenVox versions, it's best to revise your modules to replace the `hiera_*` functions with `lookup`.
While revising, consider refactoring code to use automatic class parameter lookup instead of manual lookup calls.
Because automatic lookups can now do unique and hash merges, the use of `hiera_array` and `hiera_hash` are not as important as they used to be.

Related topics: [automatic class parameter lookup][automatic], [unique and hash merges][merging].

## Adding Hiera data to a module

Modules need default values for their class parameters. Before, the preferred way to do this was the "params.pp" pattern. With Hiera 5, you can use the "data in modules" approach instead.

> Note: The "params.pp" pattern is still valid. But if you want to use Hiera data instead, you now have that option.

### Module data with the "params.pp" pattern

The "params.pp" pattern takes advantage of Puppet class inheritance behavior:

- One class in your module sets variables for the other classes: `<MODULE>::params`.
- This class uses Puppet code to construct values using conditional logic based on the target operating system.
- The rest of the classes in the module inherit from the params class, using its variables as default parameter values.
- When using the "params.pp" pattern, the values set in `params.pp` cannot be used in lookup merges — they are only used for defaults when no values are found in Hiera.

An example params class:

```puppet
# ntp/manifests/params.pp
class ntp::params {
  $autoupdate = false,
  $default_service_name = 'ntpd',

  case $facts['os']['family'] {
    'AIX': {
      $service_name = 'xntpd'
    }
    'Debian': {
      $service_name = 'ntp'
    }
    'RedHat': {
      $service_name = $default_service_name
    }
  }
}
```

A class that inherits from the params class:

```puppet
# ntp/manifests/init.pp
class ntp (
  $autoupdate   = $ntp::params::autoupdate,
  $service_name = $ntp::params::service_name,
) inherits ntp::params {
 ...
}
```

### Module data with a one-off custom Hiera backend

With Hiera 5's custom backend system, you can convert an existing params class to a hash-based Hiera backend. Create a function written in the Puppet language that returns a hash:

```puppet
# ntp/functions/params.pp
function ntp::params(
  Hash                  $options,
  Puppet::LookupContext $context,
) {
  $base_params = {
    'ntp::autoupdate'   => false,
    'ntp::service_name' => 'ntpd',
  }

  $os_params = case $facts['os']['family'] {
    'AIX': {
      { 'ntp::service_name' => 'xntpd' }
    }
    'Debian': {
      { 'ntp::service_name' => 'ntp' }
    }
    default: {
      {}
    }
  }

  $base_params + $os_params
}
```

Tell Hiera to use it by adding it to the module layer `hiera.yaml`.
Add it to the `default_hierarchy` for exact "params.pp" behavior (only used as defaults, not merged), or to the regular `hierarchy` if you want values to be merged:

```yaml
# ntp/hiera.yaml
---
version: 5
hierarchy:
  - name: "NTP class parameter defaults"
    data_hash: "ntp::params"
```

With Hiera-based defaults, you can simplify your module's main classes — they do not need to inherit from any other class, and you do not need to explicitly set default values:

```puppet
# ntp/manifests/init.pp
class ntp (
  $autoupdate,
  $service_name,
) {
 ...
}
```

### Module data with YAML data files

You can also manage your module's default data with basic Hiera YAML files:

```yaml
# ntp/hiera.yaml
---
version: 5
defaults:
  datadir: data
  data_hash: yaml_data
hierarchy:
  - name: "OS family"
    path: "os/%{facts.os.family}.yaml"

  - name: "common"
    path: "common.yaml"
```

Then put the necessary data files in the data directory:

```yaml
# ntp/data/common.yaml
---
ntp::autoupdate: false
ntp::service_name: ntpd
```

```yaml
# ntp/data/os/AIX.yaml
---
ntp::service_name: xntpd
```

```yaml
# ntp/data/os/Debian.yaml
---
ntp::service_name: ntp
```

Related topics: [class inheritance][class_inheritance], [conditional logic][conditional_logic], [custom backend system][custom_backend_system],
[write functions in the Puppet language][functions_puppet], [hash merge operator][hash_merge_operator], [module layer][layers], [automatic class parameter lookup][automatic].
