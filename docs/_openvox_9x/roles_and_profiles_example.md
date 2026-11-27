---
layout: default
title: "Roles and profiles example"
---

This example builds one profile and two roles from start to finish, so that you can see how the pieces of the roles and profiles method fit together.

## Keep time in sync with roles and profiles

Every node in this example runs chrony to keep its clock accurate. Two internal time servers follow the public NTP pool and serve time to your network.
Every other node is configured to follow those two servers.

### Set up your prerequisites

1. Create two modules named `role` and `profile` in a `site-modules` directory in your control repository. Don't declare them in your Puppetfile, because
   r10k manages the `modules` directory and removes anything there that it did not deploy. The
   [OpenVox control repository template](https://github.com/OpenVoxProject/control-repo-template) ships this layout.
2. Add `site-modules` to the `modulepath` in `environment.conf`, ahead of `modules`: `modulepath = site-modules:modules:$basemodulepath`.
3. Make sure [Hiera](./hiera_intro.html) is set up and working.

File paths in this example are relative to the control repository.

### Choose a component module

The [`puppet/chrony`](https://forge.puppet.com/modules/puppet/chrony) module, which Vox Pupuli maintains, installs and configures chrony. Add version 6.0.0
or later and its dependency, `puppetlabs/stdlib`, to your Puppetfile. That version needs OpenVox 8.19.0 or later.

### Write a profile

A profile is a normal class in the `profile` module. This one wraps the `chrony` class:

```puppet
# site-modules/profile/manifests/time.pp

# @summary Keeps the clock in sync with chrony.
#
# @param servers
#   The NTP servers this node follows.
# @param clients
#   The networks that may ask this node for the time.
class profile::time (
  Array[Stdlib::Host] $servers = ['time1.example.com', 'time2.example.com'],
  Array[String[1]]    $clients = [],
) {
  # A suspended virtual machine wakes up with the wrong time, so chrony
  # may step its clock at any time, not only during the first updates.
  if $facts['is_virtual'] {
    $makestep_updates = -1
  } else {
    $makestep_updates = 3
  }

  class { 'chrony':
    servers          => $servers,
    pools            => [],
    queryhosts       => $clients,
    makestep_updates => $makestep_updates,
  }
}
```

The `chrony` class has more than 80 parameters. The profile sets four of them, and uses each of the
[three ways a profile gets its information](the_roles_and_profiles_method.html#rules-for-profile-classes):

- It looks up the two that vary between your nodes: the servers a node follows, and the networks that may ask it for the time. Their defaults describe an
  ordinary node.
- It computes `makestep_updates`, the number of clock updates during which chrony may step the clock, from the `is_virtual` fact.
- It hardcodes an empty `pools` list, which stops the module from adding its own public pool on Debian and Ubuntu. The operating system can still supply
  sources outside the module, as Ubuntu 26.04 does in `/etc/chrony/sources.d`.

### Write roles

A role is a class that includes profiles and does nothing else. Assume two more profiles (code not shown): `profile::base`, which every node gets, and
`profile::nginx`, which sets up a web server.

```puppet
# site-modules/role/manifests/timeserver.pp
class role::timeserver {
  include profile::base
  include profile::time
}
```

```puppet
# site-modules/role/manifests/webserver.pp
class role::webserver {
  include profile::base
  include profile::time
  include profile::nginx
}
```

Both roles share `profile::time`. Its data differs between them, and you set that after you assign the roles.

### Assign the role to nodes

Each node gets exactly one role. OpenVox does not ship a node classifier, so you assign roles with Hiera, with an external node classifier (ENC), or in the
main manifest. This example uses Hiera, which keeps the assignment in the same repository, review, and deployment process as the roles.

#### Hiera

1. Set the role on the node before its first run, as an [extension request](ssl_attributes_extensions.html#extension-requests-permanent-certificate-data) in [`csr_attributes.yaml`](config_file_csr_attributes.html):

   ```yaml
   # /etc/puppetlabs/puppet/csr_attributes.yaml on the node
   ---
   extension_requests:
     pp_role: timeserver
   ```

   The CA copies the extension into the signed certificate, where Hiera reads it as `trusted.extensions.pp_role`. The node cannot change it afterwards,
   which makes it safe to classify on. The node chooses the value that it requests, so
   [check it](ssl_attributes_extensions.html#manually-checking-for-extensions-in-csrs-and-certificates) before you sign the certificate. If you cannot write `csr_attributes.yaml` when you provision a node, a custom fact works the same way in the
   hierarchy, without that protection.

2. Add a hierarchy level that is keyed on the role:

   ```yaml
   # hiera.yaml
   ---
   version: 5
   defaults:
     datadir: data
     data_hash: yaml_data
   hierarchy:
     - name: "Per-node data"
       path: "nodes/%{trusted.certname}.yaml"
     - name: "Per-role data"
       path: "roles/%{trusted.extensions.pp_role}.yaml"
     - name: "Common data"
       path: "common.yaml"
   ```

3. Name the role class in that level's data file:

   ```yaml
   # data/roles/timeserver.yaml
   classes:
     - role::timeserver
   ```

   Every role needs a file like this one. For a web server, `pp_role: webserver` selects `data/roles/webserver.yaml`, which names `role::webserver`.

4. In the main manifest, look up `classes` and include the result:

   ```puppet
   # manifests/site.pp
   lookup('classes', Array[String], 'unique', []).include
   ```

   The last argument is the default for a node with no role. Leave it empty for an empty catalog, or name a baseline such as `['role::base']`.

Keep one role class in each role data file, and keep `classes` out of the other levels. The unique merge collects the key from every level, so a class listed
at a shared level gives every node a second role. For variants of this pattern, see
[Modern Puppet node classification](https://dev.to/betadots/modern-puppet-node-classification-3ngk).

#### Other ways to assign a role

- An [ENC](nodes_external.html), such as Foreman or a script that queries your inventory, returns the classes for a node. Use one when the assignment has to
  come from outside the control repository. Have it return only the role class, and keep profile parameters in Hiera.
- [Node definitions](lang_node_definitions.html) in `site.pp` assign a role by certname or by regular expression. This is the quickest way to start, but
  every new type of node adds another expression to one shared file.

  ```puppet
  node /^time\d+\.example\.com$/ {
    include role::timeserver
  }
  ```

### Set data for the profile

Web servers need no `profile::time` overrides, because the profile's defaults describe them. The time servers need both parameters. Add them to the role's data file, below
the `classes` key:

```yaml
# data/roles/timeserver.yaml
profile::time::servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org
  - 2.pool.ntp.org
  - 3.pool.ntp.org
profile::time::clients:
  - 10.0.0.0/8
```

OpenVox looks up class parameters under the class's name, so the profile needs no change. For a value that only one node needs, use that node's file in
the `nodes` directory.

Hiera selects the role's data file by the node's `pp_role` extension, not by its role class. If you assign roles another way, set `pp_role` on the nodes
too, or key that level on something else they carry, such as a fact.
