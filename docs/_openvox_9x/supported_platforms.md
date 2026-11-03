---
layout: default
title: "Supported platforms"
---

[platforms_json]: https://github.com/OpenVoxProject/shared-actions/blob/main/platforms.json
[component_versions]: ./component_versions.html

This page lists the operating systems OpenVox builds packages for. It is generated
from [`platforms.json`][platforms_json] in `OpenVoxProject/shared-actions`, the same
list the build system uses to decide where packages are produced, so it always
matches what actually ships. The list of platforms whose packages remain available
but are no longer built comes from the package servers themselves.

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

A dagger (†) marks operating systems that also get builds for hosts running in FIPS
mode: `openvox-agent`, `openvox-server`, `openvoxdb`, and `openvoxdb-termini`, on
x86-64 only (OpenBolt has no FIPS build). See [Running OpenVox in FIPS mode](fips.html).

## OpenVox 9.x

Compared with OpenVox 8, packages are no longer built for Enterprise Linux 7, Amazon
Linux 2, Fedora 42, Debian 11, or Ubuntu 25.04, and Debian 12 gets `openvox-agent`
only (OpenVox Server and OpenVoxDB 9 need Java 21 or 25, which Debian 12 does not
provide).

{% comment %}
shared-actions keeps the newest line under "main" until the next major branches,
then gives it its own "9.x" key. Read that key when it exists so this page does not
switch to the OpenVox 10 list.
{% endcomment %}
{% assign series = site.data.supported_platforms["9.x"] | default: site.data.supported_platforms["main"] %}

<!-- markdownlint-disable MD055 MD056 -->

| Operating system | openvox-agent / OpenBolt | openvox-server / OpenVoxDB |
| --- | --- | --- |
{% for r in series.platforms %}| {{ r.os }}{% if r.fips %} †{% endif %} | {% if r.agent_bolt %}{{ r.agent_bolt | join: ", " }}{% else %}—{% endif %} | {% if r.server_db %}✓{% else %}—{% endif %} |
{% endfor %}

{% if series.legacy.size > 0 %}

### Packages available but no longer built

OpenVox 9 packages for these operating systems stay on the package servers, but
new releases are not built for them. The version shown is the last `openvox-agent`
published there.

| Operating system | Last openvox-agent |
| --- | --- |
{% for r in series.legacy %}| {{ r.os }} | {{ r.last_version | default: "—" }} |
{% endfor %}

{% endif %}

{% if site.data.supported_platforms["9.x"] %}

## Next major version (in development)

> **In development.** These are the platforms targeted by the next major OpenVox
> release while it is being developed. The list can change before that release is
> final.

{% assign series = site.data.supported_platforms["main"] %}

| Operating system | openvox-agent / OpenBolt | openvox-server / OpenVoxDB |
| --- | --- | --- |
{% for r in series.platforms %}| {{ r.os }}{% if r.fips %} †{% endif %} | {% if r.agent_bolt %}{{ r.agent_bolt | join: ", " }}{% else %}—{% endif %} | {% if r.server_db %}✓{% else %}—{% endif %} |
{% endfor %}

{% endif %}

<!-- markdownlint-enable MD055 MD056 -->

> **Enterprise Linux** covers RHEL and its rebuilds (AlmaLinux, Rocky Linux, Oracle
> Linux). A platform being listed means OpenVox publishes packages for it; see
> [Installing OpenVox](./install_pre.html) for how to configure the repository on
> your OS.
