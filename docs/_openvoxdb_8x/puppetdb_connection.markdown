---
title: "Configuring a Puppet/OpenVoxDB connection"
layout: default
canonical: "/openvoxdb/latest/puppetdb_connection.html"
---

# Configuring a Puppet/OpenVoxDB connection

[puppetdb_root]: ./overview.html
[connect_to_puppetdb]: ./connect_puppet_server.html
[confdir]: https://puppet.com/docs/puppet/latest/dirs_confdir.html
[puppetdb_conf]: ./connect_puppet_server.html#edit-puppetdb\.conf

The `puppetdb.conf` file contains the hostname and port of the [OpenVoxDB][puppetdb_root] server. It is only used if you are using OpenVoxDB and have [connected your Puppet Server to it][connect_to_puppetdb].

The Puppet Server makes HTTPS connections to OpenVoxDB to store catalogs, facts, and new reports. It also uses OpenVoxDB to answer queries, such as those necessary to support exported resources. If the OpenVoxDB instance is down, depending on the configuration of the Puppet Server, it could cause the Puppet run to fail. This document discusses configuration options for the `puppetdb.conf` file, including settings to make the OpenVoxDB terminus more tolerant of failures.

## Location

The `puppetdb.conf` file is always located at `$confdir/puppetdb.conf`. Its location is **not** configurable.

The location of the `confdir` varies, depending on the OS, Puppet distribution, and user account. [See the configuration directory documentation for details.][confdir]

## Example

    [main]
    server_urls = https://openvoxdb.example.com:8081

## Format

The `puppetdb.conf` file uses the same INI-like format as `puppet.conf`, but only uses a `[main]` section.

## `[main]` Settings

The `[main]` section defines all of the OpenVoxDB terminus settings.

### `server_urls`

This setting specifies how the Puppet Server should connect to OpenVoxDB. The configuration should look something like:

    server_urls = https://openvoxdb.example.com:8081

Puppet **requires** the use of OpenVoxDB's secure HTTPS port. You cannot use the unencrypted HTTP port.

You can use a comma-separated list of URLs if there are multiple OpenVoxDB instances available. A `server_urls` config that supports two OpenVoxDBs would look like:

    server_urls = https://puppetdb1.example.com:8081,https://puppetdb2.example.com:8081

The default value is `https://puppetdb:8081`.

The OpenVoxDB terminus will always attempt to connect to the first OpenVoxDB instance specified (listed above as `puppetdb1`). If a server-side exception occurs, or the request takes too long (see [`server_url_timeout`](#serverurltimeout)), the OpenVoxDB terminus will attempt the same operation on the next instance in the list.

### `submit_only_server_urls`

This setting allows you specify OpenVoxDB instances to which commands should be sent, but which shouldn't ever be queried for data needed during a Puppet run. It uses the same format as `server_urls`. For example:

    submit_only_server_urls = https://puppetdb-submit-only.example.com:8081

If a server is listed in `submit_only_server_urls`, it shouldn't be listed in `server_urls`; the two lists should be disjoint.

Successful command submission to the OpenVoxDB instances in this list **do** count towards any submission success thresholds you have configured.

### `server_url_timeout`

The `server_url_timeout` setting sets the maximum amount of time (in seconds) the OpenVoxDB-termini will wait for OpenVoxDB to respond to HTTP requests. If the user has specified multiple OpenVoxDB URLs and a timeout has occurred, it will attempt the same request on the next server in the list.

The default value is 30 seconds.

### `soft_write_failure`

This setting can let the Puppet Server stay partially available during a OpenVoxDB outage. If set to `true`, Puppet will keep compiling and serving catalogs even if OpenVoxDB isn't accessible for command submission. (However, any catalogs that need to **query** exported resources from OpenVoxDB will still fail.)

The default value is false.

### `include_catalog_edges`

This setting tells the OpenVoxDB terminus whether or not it should include
resource edges in catalogs sent to OpenVoxDB. For users who do not need catalog
edge information, this can improve the performance of OpenVoxDB command
processing. If you do not want to store information about catalog edges, set
this value to `false`.

The default value is true.
