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

## OpenVox 8.x

{% assign rows = site.data.supported_platforms["8.x"] %}

<!-- markdownlint-disable MD055 MD056 -->

| Operating system | openvox-agent / OpenBolt | openvox-server / OpenVoxDB |
| --- | --- | --- |
{% for r in rows %}| {{ r.os }}{% if r.fips %} †{% endif %} | {% if r.agent_bolt %}{{ r.agent_bolt | join: ", " }}{% else %}—{% endif %} | {% if r.server_db %}✓{% else %}—{% endif %} |
{% endfor %}

## Next major version (in development)

> **In development.** These are the platforms targeted by the next major OpenVox
> release while it is being developed. The list can change before that release is
> final.

{% assign rows = site.data.supported_platforms["main"] %}

| Operating system | openvox-agent / OpenBolt | openvox-server / OpenVoxDB |
| --- | --- | --- |
{% for r in rows %}| {{ r.os }}{% if r.fips %} †{% endif %} | {% if r.agent_bolt %}{{ r.agent_bolt | join: ", " }}{% else %}—{% endif %} | {% if r.server_db %}✓{% else %}—{% endif %} |
{% endfor %}
<!-- markdownlint-enable MD055 MD056 -->

> **Enterprise Linux** covers RHEL and its rebuilds (AlmaLinux, Rocky Linux, Oracle
> Linux). A platform being listed means OpenVox publishes packages for it; see
> [Installing OpenVox](./install_pre.html) for how to configure the repository on
> your OS.
