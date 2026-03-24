# OpenVox Docs

Documentation and reference generation tooling for the [OpenVox](https://github.com/OpenVoxProject) Puppet distribution.

## What's in this repo

- **Reference documentation** under `docs/`: resource types, functions, man pages, facts, and HTTP API docs for the latest OpenVox release.
- **Reference generation tooling** (`lib/`, `Rakefile`) to regenerate those docs from a given OpenVox or Facter commit.
Most narrative documentation (language reference, installation guides, etc.) was migrated to a CMS in the Puppet 5.5 era and is no longer in this repository.

## Building the site

```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/mkdocs serve      # live-reload dev server on localhost:8000
.venv/bin/mkdocs build      # build to site/
```

## Regenerating reference docs

Reference docs are generated automatically by the publish workflow when a release is created. To regenerate locally for development:

```bash
bundle install
bundle exec rake references:puppet VERSION=<tag-or-commit>
bundle exec rake references:facter VERSION=<tag-or-commit>
```

Generated files land in `references_output/` — copy them into `docs/puppet/` to preview locally. They are not committed to the repo.

## Publishing versioned docs

Docs are versioned with [mike](https://github.com/jimporter/mike). Each OpenVox major release gets its own version (e.g. `8`), and the `latest` alias always points to the most recent release.

Publishing happens automatically on GitHub release. To deploy manually:

```bash
# Deploy version 8 and mark it as latest
mike deploy --push --update-aliases 8 latest

# List deployed versions
mike list
```

The published versions live on the `gh-pages` branch and are served from GitHub Pages.

## Contributing

File issues and pull requests via the [GitHub issue tracker](https://github.com/OpenVoxProject/openvox-docs/issues).

## Copyright

Original content copyright (c) 2009–2024 Puppet, Inc. OpenVox modifications copyright (c) 2024–2025 the OpenVox contributors. See LICENSE for details.
