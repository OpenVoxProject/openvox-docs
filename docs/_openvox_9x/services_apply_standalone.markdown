---
layout: default
title: "Standalone workflows with Puppet apply"
---

[apply]: services_apply.html
[apply plugins]: plugins_in_modules.html#plug-ins-under-puppet-apply
[architecture]: architecture.html#the-stand-alone-architecture
[tradeoffs]: architecture.html#differences-between-agent-server-and-stand-alone
[trusted facts]: lang_facts_and_builtin_vars.html#trusted-facts
[install]: install_pre.html
[template]: https://github.com/OpenVoxProject/control-repo-template
[controlrepo site.pp]: https://github.com/voxpupuli/controlrepo/blob/production/manifests/site.pp
[controlrepo readme]: https://github.com/voxpupuli/controlrepo#hetzner-cloud-cloud-init-userdata
[r10k]: https://github.com/puppetlabs/r10k
[schedule]: services_apply.html#managing-systems-with-puppet-apply
[enc]: nodes_external.html
[openvoxdb apply]: /openvoxdb/latest/connect_puppet_apply.html
[openbolt]: /openbolt/latest/running_bolt_commands.html
[openbolt apply]: /openbolt/latest/applying_manifest_blocks.html

In a [standalone deployment][architecture] (often called "masterless"), each node compiles and applies its own catalog with [Puppet apply][apply] instead of requesting one from a server. That fits four situations:

* **Bootstrapping the first node.** The node that will become your OpenVox Server can't get its configuration from a server that doesn't exist yet.
* **Disposable test environments.** Lab VMs, containers, and CI jobs can apply a control repository checkout with no server or certificate setup.
* **Single-node setups.** A node that only manages itself doesn't need a server.
* **Fleets that don't justify a server.** Every node holds a copy of the control repository and applies it on a schedule.

For Puppet apply's general behavior (logging, reporting, scheduling), see [the Puppet apply service page][apply]. For the trade-offs against agent-server, see the [architecture overview][tradeoffs].

## Apply a control repository standalone

[Install the openvox-agent package][install] on the node and clone your control repository onto it. These steps assume the layout of the [OpenVox control repository template][template], which applies standalone as shipped, and use paths relative to the checkout.

1. Install the Puppetfile modules into `modules/` with [r10k][]:

   ```console
   sudo /opt/puppetlabs/puppet/bin/gem install --no-document r10k
   cd /path/to/control-repo
   /opt/puppetlabs/puppet/bin/r10k puppetfile install --verbose
   ```

2. Apply the main manifest:

   ```console
   sudo /opt/puppetlabs/bin/puppet apply manifests/site.pp \
     --hiera_config hiera.yaml \
     --modulepath site-modules:modules \
     --show_diff
   ```

   The `--modulepath` must list every directory that contains modules, or plug-ins from the omitted ones won't load. In scripts and CI, add `--detailed-exitcodes` and treat exit code 2 (changes applied) as success alongside 0.

Rerun step 1 whenever the Puppetfile changes and step 2 to converge.

Alternatively, deploy the control repository into `/etc/puppetlabs/code/environments/production` with `r10k deploy environment --modules` and apply its `manifests/site.pp` without the `--hiera_config` and `--modulepath` arguments.

## Bootstrap the first node in two phases

When the node is your future OpenVox Server, its real configuration should come from a deployed environment, not a temporary checkout. The [Vox Pupuli control repository's cloud-init example][controlrepo readme] splits the bootstrap in two:

1. From the initial checkout, apply only the tagged bootstrap resources:

   ```console
   sudo /opt/puppetlabs/bin/puppet apply \
     /root/control-repo/manifests/site.pp \
     --modulepath /root/control-repo/modules:/root/control-repo/site \
     --hiera_config /root/control-repo/hiera.yaml \
     --tags r10k,hacked_pluginsync
   ```

   This configures r10k and fills the [plug-in cache](#keep-the-plug-in-cache-in-sync). `--tags` limits which resources are *applied*, not what is compiled, so the checkout still needs its Puppetfile modules installed and its Hiera data reachable.

2. Deploy the real environment with the r10k configuration from phase 1, then apply from it:

   ```console
   sudo /opt/puppetlabs/puppet/bin/r10k deploy environment \
     --modules --verbose
   sudo /opt/puppetlabs/bin/puppet apply \
     /etc/puppetlabs/code/environments/production/manifests/site.pp
   ```

Once the node's role includes the OpenVox Server profile, later runs can switch to `puppet agent -t` against the new server.

## Run a fleet without a server

Running every node standalone means replacing what the server did centrally. The [architecture overview][tradeoffs] covers the trade-offs, [Managing systems with Puppet apply][schedule] covers scheduling runs, and [Connecting standalone nodes to OpenVoxDB][openvoxdb apply] covers central reports and inventory, which need a client certificate on every node. Two things those pages leave out:

* **Node identity.** Under Puppet apply, nothing verifies a node's identity. `$trusted['certname']` is whatever the node's `certname` setting says, and `$trusted['extensions']` is always empty, even on a node that still has its agent certificate, so classification by a certificate extension such as `pp_role` finds nothing.
  Classify from Hiera by certname, from an external fact, or with an [external node classifier][enc].
* **Central control.** No server means no central place to trigger a run. [OpenBolt][openbolt] can run Puppet apply on every node over SSH or WinRM, from a workstation or a CI job. It can also [compile each node's catalog itself and apply it][openbolt apply], so the nodes need no copy of the control repository.

If the nodes were agents before, stop and disable the agent service so it stops trying to reach the old server:

```console
sudo /opt/puppetlabs/bin/puppet resource service puppet \
  ensure=stopped enable=false
```

## Keep the plug-in cache in sync

Puppet apply loads module plug-ins directly from the modulepath, but it doesn't fill the plug-in cache that commands such as `facter -p` read (see [Plug-ins under Puppet apply][apply plugins]). The [Vox Pupuli control repository's site.pp][controlrepo site.pp] opens with a resource that fills the cache as part of the catalog:

```puppet
# hack pluginsync as file resource. only required for `puppet apply` usage
# this works by accident with puppet agent, but only on the puppetserver
# it breaks puppet agent on other systems, so we need to guard it
if $trusted['authenticated'] == 'local' {
  file { $settings::libdir:
    ensure  => directory,
    source  => 'puppet:///plugins', # lint:ignore:puppet_url_without_modules
    recurse => true,
    purge   => true,
    backup  => false,
    noop    => false,
    tag     => 'hacked_pluginsync',
  }
}
```

It copies every module's plug-ins into the directory that pluginsync maintains on agent-managed nodes. It has no effect on the run that applies it.

* **The guard** is true only for catalogs compiled locally by Puppet apply (see [trusted facts][]). On agent-managed nodes the agent manages this directory itself and an unguarded copy of the resource conflicts with it, so never deploy it unguarded to a mixed fleet.
* **The tag** lets a bootstrap script apply just this resource with `--tags`, as in [Bootstrap the first node in two phases](#bootstrap-the-first-node-in-two-phases).
* **External facts** have a parallel mount and cache directory. To make them visible to cache readers too, add a second file resource inside the same guard, with `$settings::pluginfactdest` as the title and `puppet:///pluginfacts` as the source.
