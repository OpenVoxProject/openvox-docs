---
layout: default
title: "Supported platforms"
---

[platforms_json]: https://github.com/OpenVoxProject/shared-actions/blob/main/platforms.json
[component_versions]: ./component_versions.html

This page lists the operating systems OpenVox builds packages for. It is generated
from [`platforms.json`][platforms_json] in `OpenVoxProject/shared-actions`, the same
list the build system uses to decide where packages are produced, so it always
matches what actually ships.

For the component versions inside a given release (Ruby, OpenSSL, JRuby, and so on),
see [Component versions in recent releases][component_versions].

## How to read these tables

OpenVox ships on two build systems, which is why each row has two columns:

- **openvox-agent / OpenBolt** — the Ruby components, built per CPU architecture.
  The cell lists the architectures available for that OS.
- **openvox-server / OpenVoxDB** — the JVM components, which are
  architecture-independent. A check mark means packages are built for that OS; a
  dash means they are not (the agent still runs there, but you would run the server
  or database on a different platform).

A dagger (†) marks operating systems with FIPS-validated builds. FIPS builds are
x86-64 only.

## OpenVox 9.x

OpenVox 9 is built from the `main` platform list in `shared-actions`. Compared with
OpenVox 8, packages are no longer built for Enterprise Linux 7, Amazon Linux 2,
Fedora 42, Debian 11, or Ubuntu 25.04, and Debian 12 gets `openvox-agent` only
(OpenVox Server and OpenVoxDB 9 need Java 21 or 25, which Debian 12 does not
provide).

{% assign rows = site.data.supported_platforms["main"] %}

<!-- markdownlint-disable MD055 MD056 -->

| Operating system | openvox-agent / OpenBolt | openvox-server / OpenVoxDB |
| --- | --- | --- |
{% for r in rows %}| {{ r.os }}{% if r.fips %} †{% endif %} | {% if r.agent_bolt %}{{ r.agent_bolt | join: ", " }}{% else %}—{% endif %} | {% if r.server_db %}✓{% else %}—{% endif %} |
{% endfor %}
<!-- markdownlint-enable MD055 MD056 -->

> **Enterprise Linux** covers RHEL and its rebuilds (AlmaLinux, Rocky Linux, Oracle
> Linux). A platform being listed means OpenVox publishes packages for it; see
> [Installing OpenVox](./install_pre.html) for how to configure the repository on
> your OS.
