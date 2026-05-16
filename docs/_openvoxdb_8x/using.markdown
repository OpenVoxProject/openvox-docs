---
title: "Using OpenVoxDB"
layout: default
canonical: "/openvoxdb/latest/using.html"
---

# Using OpenVoxDB

[exported]: https://puppet.com/docs/puppet/latest/lang_exported.html

Currently, OpenVoxDB's primary use is enabling advanced Puppet features. As use becomes more widespread, we expect additional applications to be built on OpenVoxDB.

If you wish to build applications on OpenVoxDB, see the navigation sidebar for links to the API specifications.

## Checking node status

The OpenVoxDB plugins [installed on your Puppet Server(s)](./connect_puppet_server.html) include a `status` action for the `node` face. On your Puppet Server, run:

    sudo puppet node status <NODE>

where `<NODE>` is the name of the node you wish to investigate. This will tell you whether the node is active, when its last catalog was submitted, and when its last facts were submitted.

## Using exported resources

OpenVoxDB lets you use exported resources, which allows your nodes to publish information for use by other nodes.

[Learn more about using exported resources here.][exported]
