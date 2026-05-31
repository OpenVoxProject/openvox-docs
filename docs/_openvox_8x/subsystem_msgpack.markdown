---
layout: default
title: "Msgpack serialization support"
---

## Background on Msgpack

OpenVox agents and servers communicate over HTTPS, exchanging structured data in JSON by default. (PSON, a JSON-like format that also allows binary data, is a legacy alternative that must be selected explicitly.)

[Msgpack](https://msgpack.org/) is an efficient (in space and time) serialization protocol that behaves similarly to JSON. It can provide faster and more compact serialization for agent/server communications.

Msgpack is an optional, opt-in optimization — JSON is the default and requires no additional setup.
Before enabling msgpack, weigh the deployment cost described below, because the `msgpack` gem is not bundled with OpenVox and has no precompiled build for the agent's Ruby.

## Requirements and caveats

Msgpack depends on the `msgpack` gem, which is not shipped in the OpenVox agent or server packages. Both OpenVox Server and every agent that uses msgpack must be able to load it:

* **OpenVox Server** runs on JRuby, so `puppetserver gem install msgpack` installs a precompiled (`-java`) gem with no build step.
* **Agents** run on standard (MRI) Ruby, for which the `msgpack` gem publishes no precompiled build. Installing it compiles a native C extension on the node, which requires a build toolchain
  (`gcc`, `make`, and the Ruby headers shipped with OpenVox). **Many hardened or production environments do not allow build tools on managed nodes.** In that case you must build the gem on a
  matching host out of band and distribute the compiled gem yourself, or stay on the default JSON serialization.

Enabling msgpack requires **both** the gem and the setting on each agent.
Setting `preferred_serialization_format` to `msgpack` on an agent that cannot load the gem has no effect: the agent logs that the msgpack feature is missing and falls back to JSON.

Because of this, msgpack is best suited to testing or to environments where you can manage the native gem. For most deployments the default JSON serialization is the right choice.

## Enabling Msgpack serialization

1. Install the [`msgpack` gem](https://rubygems.org/gems/msgpack) on OpenVox Server and on every agent that will use msgpack, using the Ruby that ships with OpenVox:
    * On OpenVox Server, use `puppetserver gem install msgpack`, then restart the OpenVox Server service.
    * On \*nix agents, use `sudo /opt/puppetlabs/puppet/bin/gem install msgpack`. This compiles a native extension, so the node needs a build toolchain (for example `gcc` and `make`).
    * On Windows agents, use the bundled Ruby's gem command: `& "C:\Program Files\Puppet Labs\OpenVox\puppet\bin\gem.bat" install msgpack` (also requires a compiler).
2. On any number of agent nodes, set [the `preferred_serialization_format` setting](configuration.html#preferred_serialization_format) to `msgpack` (in the `[agent]` or `[main]` section of `puppet.conf`).

Once this is configured, OpenVox Server uses msgpack when serving any agents that both have the gem installed and have `preferred_serialization_format` set to `msgpack`.
Agents that are missing either piece continue to use the default JSON serialization.
