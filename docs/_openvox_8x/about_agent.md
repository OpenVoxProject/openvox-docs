---
layout: default
title: "Component versions in OpenVox-agent"
---

[OpenFact]: /openfact/latest/
[Hiera]: ./hiera_intro.html
[agent]: ./services_agent_unix.html
[apply]: ./services_apply.html
[OpenVox Server]: /openvox-server/latest/
[release notes]: ./release_notes.html

## Release contents of `OpenVox-agent` 8.x

See the table for details about which components shipped in which `openvox-agent` release, and the [package-specific release notes][release notes] for more information about packaging and installation fixes and features.

| OpenVox release | OpenFact | Ruby   | OpenSSL |
|-----------------|----------|--------|---------|
| 8.26.2          | 5.6.0    | 3.2.11 | 3.0.20  |
| 8.26.1          | 5.6.0    | 3.2.11 | 3.0.20  |
| 8.26.0          | 5.6.0    | 3.2.11 | 3.0.20  |
| 8.25.0          | 5.4.0    | 3.2.10 | 3.0.19  |

## What `openvox-agent` and OpenVox Server are

We distribute OpenVox as two core packages.

- `openvox-agent` --- This package contains OpenVox's main code and all of the dependencies needed to run it, including [OpenFact][], [Hiera][], and bundled versions of Ruby and OpenSSL. Once it's installed, you have everything you need to run [the OpenVox agent service][agent] and the [`puppet apply` command][apply].
- `openvox-server` --- This package depends on `openvox-agent`, and adds the JVM-based [OpenVox Server][] application. Once it's installed, OpenVox Server can serve catalogs to nodes running the OpenVox agent service.

## How version numbers work

OpenVox Server is a separate application that, among other things, runs instances of the OpenVox server application. It has its own version number separate from the version of OpenVox it runs and may be compatible with more than one existing OpenVox version.

The `openvox-agent` package also has its own version number, which doesn't necessarily match the version of OpenVox it installs.

Order is important in the upgrade process. First, update OpenVox Server, then you update `openvox-agent`. If you upgrade OpenVox Server or OpenVoxDB to version 8, if you're on the master it will automatically upgrade the `openvox-agent` package to OpenVox agent 8.0.0 or newer. OpenVox Server 8 will also prevent you from installing anything lower than `openvox-agent` 8.0.0 on your agent nodes.

Since the `openvox-agent` package distributes several different pieces of software, its version number will frequently increase when OpenVox's version does not --- for example, `openvox-agent` 8.25.0 shipped the same OpenVox version but different Facter versions. Similarly, new versions of OpenVox Server usually don't require updates to the core OpenVox code.

This versioning scheme helps us avoid a bunch of "empty" OpenVox releases where the version number increases without any changes to OpenVox itself.
