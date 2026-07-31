---
layout: default
title: "Component versions in recent OpenVox releases"
---

[about_agent]: ./about_agent.html
[openfact]: /openfact/latest/
[openbolt]: /openbolt/latest/
[openbolt_apply]: /openbolt/latest/applying_manifest_blocks.html
[server_install_pre]: /openvox-server/latest/install_pre.html
[openvoxdb_postgres]: /openvoxdb/latest/configure_postgres.html
[sbom_tools]: https://github.com/OpenVoxProject/openvox-sbom-tools

{% assign nav_key = page.nav %}

This page lists the versions of each stack component shipped in recent OpenVox
releases, so you can answer "what's actually in this release?" in one place.

## Why there are several tables

Unlike a single bundled product, OpenVox ships its components on **independent
version lines**. `openvox-agent`, `openvox-server`, `openvoxdb`, and `openbolt` are
released separately and do not share a version number (for example, the newest
agent, server, and database releases all carry different versions, and OpenBolt is
on its own 5.x line). There is no single "OpenVox platform version" that pins all
of them at once, so each component is shown in its own table, keyed by that
component's release.

The bundled-component columns are **generated** from the per-release SBOMs published
by [openvox-sbom-tools][sbom_tools] for every component, so they don't drift. Columns
that aren't bundled anywhere (Java and PostgreSQL) are supported-version requirements
maintained by hand; see the note under each table.

<!-- markdownlint-disable MD055 MD056 -->

## Agent and runtime components

These ship inside the `openvox-agent` package (see [About openvox-agent][about_agent]).
The OpenFact column is the **bundled** OpenFact version and links to the
[OpenFact documentation][openfact], which is the authoritative source for OpenFact
changes; this page is only a pointer.

| OpenVox release | OpenFact | Ruby | OpenSSL | curl |
| --- | --- | --- | --- | --- |
{% for r in site.data.agent_release_contents[nav_key] %}| {{ r.release }} | [{{ r.openfact }}][openfact] | {{ r.ruby }} | {{ r.openssl }} | {{ r.curl }} |
{% endfor %}

## Server components

These ship with the `openvox-server` package. JRuby is the bundled version, read
from the server's per-release SBOM.

| OpenVox Server release | JRuby | Java |
| --- | --- | --- |
{% for r in site.data.server_release_contents[nav_key] %}| {{ r.release }} | {{ r.jruby }} | 17, 21 |
{% endfor %}

> **Java is not bundled.** OpenVox Server requires a supported JDK to be installed
> separately. The Java column shows the currently supported major versions, not a
> per-release pin; see [Before you install OpenVox Server][server_install_pre].

## Data components

OpenVoxDB ships in the `openvoxdb` package on its own release line. The
`openvoxdb-termini` package (the terminus plugins that let OpenVox Server and
agents talk to OpenVoxDB) is released in lockstep at the **same version** as
`openvoxdb`, so it is not listed separately.

Jetty is the bundled HTTP server, read from the OpenVoxDB SBOM.

| OpenVoxDB release | Jetty | Java | PostgreSQL |
| --- | --- | --- | --- |
{% for r in site.data.openvoxdb_release_contents[nav_key] %}| {{ r.release }} | {{ r.jetty }} | 11, 17 | 11+ (14+ recommended) |
{% endfor %}

> **Java and PostgreSQL are not bundled.** OpenVoxDB runs on a JVM and connects to a
> PostgreSQL server you install separately (the `puppet-openvoxdb` module can install
> PostgreSQL for you). The Java column shows the currently supported major versions,
> and the PostgreSQL column the supported minimum (PostgreSQL 11; version 14 or newer
> recommended) — neither is a per-release pin. See
> [Configuring PostgreSQL][openvoxdb_postgres].

## OpenBolt

[OpenBolt][openbolt] is the orchestration tool. It is not part of the
agent/server/data stack above and ships on its own **5.x** release line, bundling
its own runtime. See the [OpenBolt documentation][openbolt] for OpenBolt's own
release notes.

OpenBolt is the only OpenVox package that **bundles r10k**. Although r10k is
typically run on a server to deploy environments from a control repo, it is not
shipped in `openvox-server` (or `openvox-agent`); on a server you install it
separately, for example with the `puppet/r10k` module or a `gem install`.

| OpenBolt release | OpenVox | Ruby | OpenSSL | r10k |
| --- | --- | --- | --- | --- |
{% for r in site.data.openbolt_release_contents %}| {{ r.release }} | {{ r.openvox }} | {{ r.ruby }} | {{ r.openssl }} | {{ r.r10k }} |
{% endfor %}

> **The OpenVox column is the bundled version, not something you install.** OpenBolt
> bundles OpenVox for [`bolt apply`][openbolt_apply]; its gemspec declares a range
> (`~> 8.0`) and the version shown here is the exact one resolved into the package at
> build time. For `bolt apply`, OpenBolt compiles the catalog with this bundled
> OpenVox and installs the `openvox-agent` package on targets via `apply_prep`, so
> you don't install OpenVox separately to use it.

<!-- markdownlint-enable MD055 MD056 -->

## Regenerating this page

The agent/runtime, server, OpenVoxDB, and OpenBolt columns are generated from
upstream release metadata. Regenerate the data with:

```bash
bundle exec rake references:component_versions
```

The agent, server, and OpenVoxDB tables are per-OpenVox-series: each task writes a
file named for the collection's nav_key, so the page renders its own series via
`site.data.<table>[page.nav]`. With the 8.x defaults this writes
`_data/agent_release_contents/openvox_8x.yml`,
`_data/server_release_contents/openvox_8x.yml`, and
`_data/openvoxdb_release_contents/openvox_8x.yml`. OpenBolt is independent of the
OpenVox major and is shared across series in `_data/openbolt_release_contents.yml`.

When a 9.x collection is added, run the per-series tasks again with `SERIES=9.`
(and an appropriate `MIN_RELEASE`); they write `…/openvox_9x.yml` files, and the
copied 9.x page reads them automatically through its own `page.nav`.
