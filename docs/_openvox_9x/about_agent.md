---
layout: default
title: "About openvox-agent"
---

[release_notes]: ./release_notes.html
[services_agent]: ./services_agent_unix.html
[services_apply]: ./services_apply.html
[openvox_server]: /openvox-server/latest/
[component_versions]: ./component_versions.html

`openvox-agent` is the core OpenVox package for managed nodes and standalone use.
It bundles the OpenVox runtime and the dependencies needed to run it, so it is the
package you install on Linux, macOS, and Windows agent nodes.

## What `openvox-agent` provides

The package includes:

- the `puppet` and `facter` commands
- the OpenVox agent service
- the runtime needed for `puppet apply`
- bundled dependencies such as Ruby and OpenSSL

After installation, you can run the [OpenVox agent service][services_agent] or use
[standalone apply workflows][services_apply] on the same host.

## Relationship to other packages

OpenVox is usually installed as a small set of packages:

- `openvox-agent` for agent nodes and standalone use
- `openvox-server` for catalog compilation and CA services on server nodes
- `openvoxdb` for exported resources, reports, and inventory data
- `openvoxdb-termini` on server nodes that need to talk to OpenVoxDB

`openvox-server` depends on `openvox-agent`, so server upgrades often pull in a
newer `openvox-agent` package on the server at the same time.

## Versions and release notes

The `openvox-agent` package version is a package release number, not a separate
product line. It can change when bundled dependencies or packaging details change,
even if the core OpenVox language and command behavior stay the same.

For package-specific changes, see the [OpenVox release notes][release_notes] and the
latest [OpenVox Server documentation][openvox_server].

For the bundled versions of OpenFact, Ruby, OpenSSL, and curl in each
`openvox-agent` release, see
[Component versions in recent OpenVox releases][component_versions], which also
covers the server and database components.
