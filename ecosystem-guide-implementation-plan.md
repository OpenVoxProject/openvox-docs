# Ecosystem Guide Implementation Plan

## Goal

Create a new OpenVox Ecosystem documentation section that orients readers without duplicating the existing product documentation.
The ecosystem section should explain how OpenVox, OpenVox Server, OpenVoxDB, OpenFact, OpenBolt, modules, Forge, and community
resources fit together, then route readers to canonical docs for details.

## Review Context

PR #176 attempted to add a full getting started guide under a new `ecosystem` collection. The direction is useful, but the draft has two structural issues:

- It duplicates large amounts of existing OpenVox, OpenVox Server, OpenVoxDB, and OpenFact content.
- Its voice is inconsistent with the rest of the docs, with generated-sounding jokes, emoji-heavy headings, and informal commentary.

The replacement should be a tighter orientation layer, not a parallel documentation set.

## Principles

- Keep canonical content canonical. If a topic already has detailed product docs, summarize it briefly and link to that page.
- Prefer maps, learning paths, and decision guides over rewritten references.
- Keep the tone direct, neutral, and maintainable.
- Avoid jokes, emoji headings, AI attribution footers, and speculative claims.
- Use existing navigation patterns and collection conventions.
- Every new page should have front matter and render to `.html`.
- Every internal link should point to a generated page, not a source `.md` or stale `README.md` path.

## Proposed Information Architecture

Add an `ecosystem` collection with a small number of pages:

1. `index.md`
   - What the OpenVox ecosystem is.
   - Which projects are included.
   - Who should read which docs first.

2. `projects.md`
   - Short descriptions of each project.
   - Canonical links to OpenVox, OpenVox Server, OpenVoxDB, OpenFact, OpenBolt, and community module resources.

3. `learning-path.md`
   - Task-oriented paths for new users, existing Puppet users, module authors, and operators.
   - Each path should link out to canonical docs rather than recreating them.

4. `migration.md`
   - High-level migration orientation for Puppet users.
   - Link to detailed install, compatibility, configuration, and server docs.

5. `community.md`
   - Official community channels, contribution entry points, and where to ask for help.
   - Keep it factual and current.

Do not add a full language tutorial, Hiera reference, module development guide, server administration guide, OpenVoxDB guide, or troubleshooting guide in this collection.

## Canonical Sources To Link

Use these existing sections as the source of truth instead of rewriting them:

- OpenVox overview: `docs/_openvox_8x/index.md`
- OpenVox agent basics: `docs/_openvox_8x/about_agent.md`
- Architecture: `docs/_openvox_8x/architecture.markdown`
- Language reference: `docs/_openvox_8x/lang_summary.md` and related `lang_*` pages
- Resources and types: `docs/_openvox_8x/type.md`, `docs/_openvox_8x/types/`, and `docs/_openvox_8x/cheatsheet_core_types.md`
- Hiera: `docs/_openvox_8x/hiera_intro.md`, `docs/_openvox_8x/hiera_quick.md`, `docs/_openvox_8x/hiera_config_yaml_5.md`, and `docs/_openvox_8x/hiera_merging.md`
- Roles and profiles: `docs/_openvox_8x/the_roles_and_profiles_method.md`
- Modules: `docs/_openvox_8x/modules_fundamentals.md`, `docs/_openvox_8x/bgtm.md`, and `docs/_openvox_8x/cheatsheet_module.md`
- Environments: `docs/_openvox_8x/environments_about.markdown` and `docs/_openvox_8x/environment_isolation.md`
- Configuration: `docs/_openvox_8x/config_about_settings.markdown`, `docs/_openvox_8x/config_important_settings.markdown`,
  `docs/_openvox_8x/config_file_main.markdown`, `docs/_openvox_8x/config_print.markdown`, and `docs/_openvox_8x/config_set.markdown`
- Certificates and CA: `docs/_openvox-server_8x/http_certificate.md`, `docs/_openvox-server_8x/http_certificate_request.md`,
  `docs/_openvox-server_8x/http_certificate_status.md`, `docs/_openvox-server_8x/http_certificate_clean.markdown`, and
  `docs/_openvox_8x/config_file_autosign.markdown`
- OpenVox Server: `docs/_openvox-server_8x/index.markdown`, `docs/_openvox-server_8x/configuration.markdown`,
  `docs/_openvox-server_8x/services_puppetserver.markdown`, `docs/_openvox-server_8x/restarting.markdown`, and
  `docs/_openvox-server_8x/scaling_puppet_server.markdown`
- OpenVoxDB: `docs/_openvoxdb_8x/index.md`, `docs/_openvoxdb_8x/overview.markdown`, `docs/_openvoxdb_8x/install_from_packages.markdown`, `docs/_openvoxdb_8x/configure.markdown`, and `docs/_openvoxdb_8x/api/query/tutorial-pql.markdown`
- OpenFact: `docs/_openfact_5x/index.md`, `docs/_openfact_5x/fact_overview.md`, `docs/_openfact_5x/configuring_openfact.md`, and `docs/_openfact_5x/custom_facts.md`
- OpenBolt: `https://github.com/OpenVoxProject/openbolt`

If a referenced file does not currently render or is missing from navigation, fix that in the canonical section rather than copying the content into the ecosystem guide.

## Implementation Tasks

1. Add collection and navigation
   - Add `ecosystem_latest` and versioned collection entries to `_config.yml`.
   - Add an ecosystem nav file under `_data/nav/`.
   - Add an entry to `_data/nav_map.yml`.
   - Add a latest symlink under `docs/`.
   - Add the ecosystem section to the home page feature list if it fits the current homepage model.

2. Draft concise pages
   - Keep pages short.
   - Link to canonical docs for details.
   - Avoid copying command blocks unless they are necessary to orient the reader.
   - Prefer "Start here" lists over full tutorials.

3. Validate links
   - Build locally with Jekyll.
   - Check that all ecosystem pages render as `.html`.
   - Check that internal ecosystem links do not point to `.md`, `README.md`, or missing paths.

4. Normalize style
   - Remove emoji from headings and titles.
   - Remove informal jokes and generated-sounding commentary.
   - Use sentence case where existing docs expect it.
   - Run markdownlint against the new files and fix issues introduced by this branch.

5. Review for duplication
   - For every section longer than a short summary, confirm whether the content already exists elsewhere.
   - Replace duplicated reference material with a link to the canonical page.

## Acceptance Criteria

- The new ecosystem section builds successfully with Jekyll.
- No ecosystem page is emitted as raw `.md`.
- New ecosystem pages pass markdownlint.
- Internal links in the ecosystem section resolve to generated pages.
- The section contains orientation and route-finding content only, not a second language, Hiera, module, server, or OpenVoxDB manual.
- Tone matches the existing docs: factual, concise, and professional.
- The branch remains local until explicitly pushed.

## Decisions

- OpenBolt does not need a first-class docs collection before this work can proceed. The ecosystem guide should mention OpenBolt as part of
  the ecosystem and link to `https://github.com/OpenVoxProject/openbolt` until local OpenBolt docs exist.
- Community links should not be duplicated as a long-maintained directory in this repo. The ecosystem guide should point primarily to
  Vox Pupuli Connect and include only stable, high-value links such as the OpenVox GitHub organization and docs contribution path.
- Start from clean drafts. PR #176 can be used as context for topic coverage, but prose and structure should be rewritten to match this
  plan rather than copied and edited in place.
