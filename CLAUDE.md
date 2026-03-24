# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repo contains:

1. **Reference documentation** (`docs/`) for the latest OpenVox release — resource types, functions, man pages, facts, HTTP API. Built with MkDocs + Material theme.
2. **Reference generation tooling** (`lib/puppet_references/`, `Rakefile`) — Ruby code that checks out an OpenVox or Facter source commit and generates Markdown reference pages from it.

## MkDocs

```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt  # first-time setup
.venv/bin/mkdocs serve          # live-reload dev server on localhost:8000
.venv/bin/mkdocs build          # build to site/
```

Warnings about broken cross-links are expected — most Puppet language reference pages were migrated to a CMS and aren't in this repo.

## Reference Doc Generation

```bash
bundle install
bundle exec rake references:puppet VERSION=<git-tag-or-commit>   # generate Puppet reference docs
bundle exec rake references:facter VERSION=<git-tag-or-commit>   # generate Facter reference docs
bundle exec rake references:version_tables                        # generate version tables
```

Generated files land in `references_output/` and must be manually moved into `docs/puppet/<version>/`.

## Linting

```bash
bundle exec rake rubocop
```

## Architecture

### Reference generation (`lib/puppet_references/`)

Checks out the specified VERSION of OpenVox or Facter into `vendor/`, then introspects the source to generate Markdown:

- `puppet/type.rb` / `puppet/type_strings.rb` — resource type reference
- `puppet/functions.rb` — function reference
- `puppet/man.rb` — man pages (generated as Markdown)
- `puppet/http.rb` — HTTP API docs
- `facter/core_facts.rb` — core facts reference
- `facter/facter_cli.rb` — Facter CLI reference

Output goes to `references_output/`; the `latest` path for each reference is printed at the end of the run.

### CI

GitHub Actions (`.github/workflows/test.yml`) runs `bundle exec rake rubocop` on PRs and pushes to master.
