---
layout: default
title: "Msgpack serialization support"
---

## Background on Msgpack

OpenVox agents and servers communicate over HTTPS, exchanging structured data in JSON by default. (PSON, a JSON-like format that also allows binary data, is a legacy alternative that must be selected explicitly.)

[Msgpack](https://msgpack.org/) is an efficient (in space and time) serialization protocol that behaves similarly to JSON. It can provide faster and more compact serialization for agent/server communications.

When msgpack is enabled, OpenVox Server and the OpenVox agent communicate using msgpack instead of the default JSON serialization.

Msgpack support is optional and turned off by default. It depends on the `msgpack` gem, which is not bundled with the OpenVox agent or server packages, so you must install it yourself before enabling it.

## Enabling Msgpack serialization

1. Install the [`msgpack` gem](https://rubygems.org/gems/msgpack) on OpenVox Server and on all agent nodes, using the Ruby that ships with OpenVox:
    * On \*nix nodes, use `sudo /opt/puppetlabs/puppet/bin/gem install msgpack`.
    * On Windows nodes, use the bundled Ruby's gem command: `& "C:\Program Files\Puppet Labs\OpenVox\puppet\bin\gem.bat" install msgpack`.
    * On OpenVox Server, use `puppetserver gem install msgpack`, then restart the OpenVox Server service.
2. On any number of agent nodes, set [the `preferred_serialization_format` setting](configuration.html#preferred_serialization_format) to `msgpack` (in the `[agent]` or `[main]` section of `puppet.conf`).

Once this is configured, OpenVox Server uses msgpack when serving any agents that have `preferred_serialization_format` set to `msgpack`. Any agents without that setting continue to use the default JSON serialization.
