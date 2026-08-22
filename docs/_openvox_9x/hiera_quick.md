---
layout: default
title: "Getting started with Hiera"
---

[layers]: ./hiera_intro.html#hieras-three-config-layers
[merging]: ./hiera_merging.html#merge-behaviors
[v5]: ./hiera_config_yaml_5.html
[yaml]: https://yaml.org/spec/1.2/spec.html
[hierarchies]: ./hiera_intro.html#hiera-hierarchies
[variables]: ./hiera_merging.html#interpolating-variables
[automatic]: ./hiera_automatic.html
[certname]: ./lang_facts_and_builtin_vars.html#trusted-facts
[cli]: ./man/lookup.html
[confdir]: ./dirs_confdir.html
[codedir]: ./dirs_codedir.html

This page introduces the basic concepts and tasks to get you started with Hiera, including how to create a hiera.yaml config file and write data.
It is the foundation for understanding the more advanced topics described in the rest of the Hiera documentation.

Related topics: [global layer and module layer][layers], [hash and array merging][merging].

## Create a hiera.yaml config file

The Hiera config file is called `hiera.yaml`. Each environment should have its own `hiera.yaml` file.

1. In the main directory of one of your environments, create a new file called `hiera.yaml`. Paste the following contents into it:

   ```yaml
   # <ENVIRONMENT>/hiera.yaml
   ---
   version: 5

   hierarchy:
     - name: "Per-node data"                   # Human-readable name.
       path: "nodes/%{trusted.certname}.yaml"  # File path, relative to datadir.
                                      # ^^^ IMPORTANT: include the file extension!

     - name: "Per-OS defaults"
       path: "os/%{facts.os.family}.yaml"

     - name: "Common data"
       path: "common.yaml"
   ```

   This file is in a format called YAML, which is used extensively throughout Hiera.

Related topics: [The hiera.yaml (v5) reference][v5], [YAML specification][yaml].

## The hierarchy

The `hiera.yaml` file configures a hierarchy: an ordered list of data sources.

Hiera searches these data sources in the order they are written. Higher-priority sources override lower-priority ones.
Most hierarchy levels use variables to locate a data source, so that different nodes get different data.

This is the core concept of Hiera: a defaults-with-overrides pattern for data lookup, using a node-specific list of data sources.

Related topics: [hierarchies][hierarchies], [variables][variables].

## Write data: Create a test class

A test class writes the data it receives to a temporary file on the agent when applying the catalog.

Hiera is used with OpenVox code, so the first step is to create an OpenVox class for testing.

1. If you do not already use the roles and profiles method, create a module named `profile`. Profiles are wrapper classes that use multiple component modules to configure a layered technology stack.

2. Create a class called `hiera_test.pp` in your `profile` module.

3. Add the following code to your `hiera_test.pp` file:

   ```puppet
   # /etc/puppetlabs/code/environments/production/modules/profile/manifests/hiera_test.pp
   class profile::hiera_test (
     Boolean             $ssl,
     Boolean             $backups_enabled,
     Optional[String[1]] $site_alias = undef,
   ) {
     file { '/tmp/hiera_test.txt':
       ensure  => file,
       content => @("END"),
                  Data from profile::hiera_test
                  -----
                  profile::hiera_test::ssl: ${ssl}
                  profile::hiera_test::backups_enabled: ${backups_enabled}
                  profile::hiera_test::site_alias: ${site_alias}
                  |END
       owner   => root,
       mode    => '0644',
     }
   }
   ```

   The test class uses class parameters to request configuration data. OpenVox looks up class parameters in Hiera, using `<CLASS NAME>::<PARAMETER NAME>` as the lookup key.

4. Make a manifest that includes the class:

   ```puppet
   # site.pp
   include profile::hiera_test
   ```

5. Compile the catalog and observe that this fails because there are required values.

6. To provide values for the missing class parameters, set the following keys in your Hiera data:

   Parameter          | Hiera key
   -------------------|---------------------------------------
   `$ssl`             | `profile::hiera_test::ssl`
   `$backups_enabled` | `profile::hiera_test::backups_enabled`
   `$site_alias`      | `profile::hiera_test::site_alias`

7. Compile again and observe that the parameters are now automatically looked up.

Related topics: [Automatic class parameter lookup][automatic].

## Write data: Set values in common data

Set values in your common data — the level at the bottom of your hierarchy.

This hierarchy level uses the YAML backend for data, which means the data goes into a YAML file. To know where to put that file, combine the following pieces of information:

* The current environment's directory.
* The data directory, which is a subdirectory of the environment. By default, it's `<ENVIRONMENT>/data`.
* The file path specified by the hierarchy level.

In this case, `/etc/puppetlabs/code/environments/production/` + `data/` + `common.yaml`.

1. Open that YAML file in an editor, and set values for two of the class's parameters.

   ```yaml
   # /etc/puppetlabs/code/environments/production/data/common.yaml
   ---
   profile::hiera_test::ssl: false
   profile::hiera_test::backups_enabled: true
   ```

   The third parameter, `$site_alias`, has a default value defined in code, so you can omit it from the data.

## Write data: Set per-operating system data

The second level of the hierarchy uses the `os` fact to locate its data file. This means it can use different data files depending on the operating system of the current node.

For this example, suppose that your developers use MacBook laptops, which have an OS family of `Darwin`.
If a developer is running an app instance on their laptop, it should not send data to your production backup server, so set `$backups_enabled` to `false`.

If you do not run OpenVox on any Mac laptops, choose an OS family that is meaningful to your infrastructure.

1. Locate the data file by replacing `%{facts.os.family}` with the value you are targeting:

   `/etc/puppetlabs/code/environments/production/data/` + `os/` + `Darwin` + `.yaml`

2. Add the following contents:

   ```yaml
   # /etc/puppetlabs/code/environments/production/data/os/Darwin.yaml
   ---
   profile::hiera_test::backups_enabled: false
   ```

3. Compile to observe that the override takes effect.

## Write data: Set per-node data

The highest level of the example hierarchy uses the value of `$trusted['certname']` to locate its data file, so you can set data by name for each individual node.

This example supposes you have a server named `jenkins-prod-03.example.com`, and configures it to use SSL and to serve this application at the hostname `ci.example.com`.
To try this out, choose the name of a real server that you can run OpenVox on.

1. To locate the data file, replace `%{trusted.certname}` with the node name you're targeting:

   `/etc/puppetlabs/code/environments/production/data/` + `nodes/` + `jenkins-prod-03.example.com` + `.yaml`

2. Open that file in an editor and add the following contents:

   ```yaml
   # /etc/puppetlabs/code/environments/production/data/nodes/jenkins-prod-03.example.com.yaml
   ---
   profile::hiera_test::ssl: true
   profile::hiera_test::site_alias: ci.example.com
   ```

3. Compile to observe that the override takes effect.

Related topics: [$trusted['certname']][certname].

## Testing Hiera data on the command line

As you set Hiera data or rearrange your hierarchy, it is important to double-check the data a node will receive.

The `puppet lookup` command helps test data interactively. For example:

```sh
puppet lookup profile::hiera_test::backups_enabled --environment production --node jenkins-prod-03.example.com
```

This returns the following value:

```yaml
--- true
```

To use the `puppet lookup` command effectively:

* Run the command on an OpenVox server node, or on another node that has access to a full copy of your OpenVox code and configuration.
* The node you are testing against should have contacted the server at least once, as this makes the facts for that node available to the lookup command
  (otherwise you will need to supply the facts yourself on the command line).
* Make sure the command uses the global `confdir` and `codedir`, so it has access to your live data. If you're not running `puppet lookup` as root user, specify `--codedir` and `--confdir` on the command line.
* If you use PuppetDB, you can use any node's facts in a lookup by specifying `--node <NAME>`. Hiera can automatically get that node's real facts and use them to resolve data.
* If you do not use PuppetDB, or if you want to test for a set of facts that don't exist, provide facts in a YAML or JSON file and specify that file as part of the command with `--facts <FILE>`.
  To get a file full of facts, rather than creating one from scratch, run `facter -p --json > facts.json` on a node that is similar to the node you want to examine,
  copy the `facts.json` file to your OpenVox server node, and edit it as needed.
* If you are not getting the values you expect, try re-running the command with `--explain`. The `--explain` flag makes Hiera output a full explanation of which data sources it searched and what it found in them.

Related topics: [The puppet lookup command][cli], [confdir][confdir], [codedir][codedir].
