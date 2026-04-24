# OpenVox Docs

Source for the OpenVox documentation site, along with an issue tracker for
reporting problems with the published docs.

## Getting started

To build the documentation in this repository, first install Ruby 3.2 or later.
Then use Bundler to install the project dependencies:

```
bundle install
```

Then build the documentation with:

```
bundle exec jekyll build
```

Or serve it locally to preview in a browser:

```
bundle exec jekyll serve
```

## Updating documentation

This section describes common workflows for updating the docs.
If you are considering a change not described here, or need help,
please chat with us in `#sig-documentation` on the
[Vox Pupuli Slack][vox-slack] (bridged to `#voxpupuli-sig-documentation`
on [Libera.Chat][libera-chat] for IRC users).

[vox-slack]: https://short.voxpupu.li/puppetcommunity_slack_signup
[libera-chat]: https://libera.chat/

The source files for docs pages can be found under the `docs/` directory.
This directory contains versioned subfolders for each project, which
then contain the Markdown files that make up documentation for that
project.

Whichever workflow you follow, run `bundle exec jekyll serve` to review
your changes locally before opening a pull request.

### Adding a new page

Create a new Markdown file under the `docs/` directory, and then edit the
YAML table of contents under `_data/nav/` to add a link to your new page.

### Adding a new project

Create a new subdirectory under `docs/` along with a new YAML table of contents
under `_data/nav/`. Then edit `_config.yml` to register the new directory:

- Add an entry to the `collections:` map to enable output.
- Add an entry to the `defaults:` map to set the table of contents.

Consider updating `index.md` to add an entry pointing to your new content.
See the [home layout reference][home-layout] for details.

[home-layout]: https://jekyll-vitepress.dev/frontmatter-reference/#home-layout-keys

### Modifying theme settings

This project uses the [Jekyll VitePress theme][jekyll-vitepress], by
[@crmne](https://github.com/crmne). Many aspects of the theme can be
customized or overridden, see the theme documentation for details.

[jekyll-vitepress]: https://jekyll-vitepress.dev/

## Copyright

Copyright (c) 2009-2024 Puppet, Inc. See LICENSE for details.
