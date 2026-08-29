---
layout: default
title: "Scaffolding New Content with Jig"
---

Puppet modules have a defined standard structure; the directories and filenames have to match their contents.
In other words, the directory name should match the module name, and each class or defined type should be a matching filename under the `manifests` directory, and so on.
This structure allows the OpenVox compiler to locate and load the proper files when including various classes and such.

{% include alert.html type="warning" title="Historical Note" content="You may stumble into very old Puppet code that doesn't maintain the 'one _thing_ per file' convention.
These are vestigial remnants of the times before the module structure was finalized.
While OpenVox can technically load content this way in some cases, it's best to just avoid that style since it leads to undefined behaviour." %}

It's possible to create files and maintain the proper directory structure by hand and nothing prevents you from doing so.
However, many people today prefer to use a scaffolding tool to maintain proper structure and consistency.
The tool we recommend for this today is [Jig](https://github.com/voxpupuli/jig).

## Installing Jig

Download the latest release for your platform from the [releases page](https://github.com/voxpupuli/jig/releases).
Uncompress it and move the `jig` binary to a path like `/usr/local/bin`.

{% include alert.html type="tip" title="macOS Security Alert" content="The packages are unsigned, so macOS won't open them by default. Run it once and cancel the warning dialog that tells you to trash it.
Then go to `System Settings -> Privacy & Security` and scroll to the bottom of the pane. You'll see the option to allow `jig` to run." %}

Jig is one of the few tools in the Vox Pupuli ecosystem implemented in Go.
If you have [Go installed](https://go.dev/doc/install), then you can choose to install via the Go package manager instead.
This will place the compiled binary into `$GOPATH/bin`, which is likely to be `~/go/bin`.
Ensure that location is in your `$PATH`.

```console
go install github.com/voxpupuli/jig@latest
```

## Creating a new module

Jig has built-in templates to create a complete Puppet module with all the standard directory structure and metadata.
It will walk you through an interactive interview to collect module metadata.

```console
$ jig new module demo
Forge username [ben.ford]: binford2k
Author name [Ben Ford]:
License type [Apache-2.0]:
Summary of the module []: This is not a real module; it just demonstrates the Jig new module interview.
Source URL for the module []: https://http.cat/status/404
Created new module demo in /Users/ben.ford/Projects/demo
```

To skip the interview and take the values from your config file, flags, or defaults instead, pass `--skip-interview` (or `-i`).
You can supply individual values with flags such as `--forge-user`, `--author`, `--license`, `--summary`, and `--source`.

Jig will create the full directory structure with starter files for the main class, Hiera data, rspec initialization helpers, etc.

```console
$ tree demo
demo
├── CHANGELOG.md
├── data
│   └── common.yaml
├── examples
├── files
├── Gemfile
├── hiera.yaml
├── jig.toml
├── manifests
│   └── init.pp
├── metadata.json
├── Rakefile
├── README.md
├── spec
│   ├── acceptance
│   │   └── init_spec.rb
│   ├── classes
│   │   └── init_spec.rb
│   ├── default_facts.yml
│   ├── spec_helper.rb
│   └── spec_helper_acceptance.rb
├── tasks
└── templates

9 directories, 14 files
```

Two of those files are written by Jig itself rather than from a template: `metadata.json`, and `jig.toml`, which holds the [per-module settings](#per-module-configuration-jigtoml) described below.
The generated `metadata.json` declares its runtime requirement as `openvox` (`>= 7.0.0 < 9.0.0`), which the Vox Pupuli test tooling understands alongside the older `puppet` name.
It also ships dotfiles that `tree` hides: `.editorconfig`, `.gitignore`, `.overcommit.yml`, `.rubocop.yml`, and a `.devcontainer/` for editors that support it.

### Adding content to a module

Jig knows how to add other content to your module.
For example, to add a `demo::foo` class you can type the following (omitting the module name):

```console
$ jig new class foo
creating class demo::foo...
```

You can create more deeply nested classes by just specifying the name.
The required directory structure will be created for you.

```console
$ jig new class foo::bar::baz
creating class demo::foo::bar::baz...
$ tree manifests
manifests
├── foo
│   └── bar
│       └── baz.pp
├── foo.pp
└── init.pp
```

Jig can create other types of content for your module:

* `class`
  * Creates a class manifest and associated spec file.
* `defined_type`
  * Creates a defined type manifest and associated spec file.
* `fact`
  * Creates a standard Ruby fact and associated spec file.
  * This does not know how to do external facts or structured data facts.
* `function`
  * Creates a new _Puppet language_ function and associated spec file.
  * This does not currently know how to create Ruby functions.
* `provider`
  * Creates a new type and provider using the [Resource API](https://github.com/puppetlabs/puppet-resource_api) and associated spec files for each.
  * If you want to add a provider for an existing type, you should create the files manually.
  * If you prefer the legacy type and provider interface, you should create those manually.
* `task`
  * Creates a new OpenBolt task and its associated metadata file.
* `test`
  * Creates a basic spec test for an existing class or defined type.
* `transport` _(uncommon)_
  * Creates a new [Resource API](https://github.com/puppetlabs/puppet-resource_api) transport and its associated files.

See [Jig's GitHub page](https://github.com/voxpupuli/jig) for full documentation.

## Configuring Jig

Jig looks for a config file at `~/.config/jig/config.toml`.
All fields are optional.
If the file does not exist, it will fall back to sensible defaults.

```toml
forge_username = "avitacco"
author         = "John Doe"
license        = "Apache-2.0"
forge_token    = "your-forge-token"
template_dir   = "~/.config/jig/templates"

# Trust unknown ssh host keys when fetching remote templates (for CI).
ssh_accept_new = false

# Run the Ruby-backed commands in a container instead of on the host.
[runner]
type   = "local"                            # "local" (default) or "voxbox"
engine = "docker"                           # "docker" (default) or "podman"
image  = "ghcr.io/voxpupuli/voxbox:latest"
```

Every field can also be set with a `JIG_`-prefixed environment variable (`JIG_FORGE_USERNAME`, `JIG_TEMPLATE_DIR`, `JIG_RUNNER_TYPE`, and so on), which takes precedence over the file.
Pass `--config` to point at a different file.

This file holds settings that belong to you: credentials, interview defaults, where your templates live.
Settings that belong to a module live in `jig.toml` instead.

### Per-module configuration (`jig.toml`)

`jig new module` writes a `jig.toml` next to `metadata.json`, and you commit it with the module so everyone working on it shares the same settings.
All three sections are optional; a missing section means Jig's defaults.

```toml
# Template repository the module was scaffolded from; later jig commands
# in this module default to it.
[template]
url    = "ssh://git@my.git.server/jig_templates.git"
ref    = "main"
commit = "<commit the templates were fetched at>"

# Files `jig renew` may re-render and overwrite. Empty by default so
# nothing is overwritten accidentally.
[renew]
paths = []

# Which files go into the module package built by `jig build`.
[build]
action     = "deny"
exceptions = []
```

`[template]` and `[renew]` are covered in the next two sections; `[build]` is covered on the [publishing page](publishing.html#what-gets-packaged).

Trust settings such as `ssh_accept_new` are deliberately never read from `jig.toml`.
A cloned repository must not be able to change security behavior for the people who clone it.
{: .tip }

## Maintaining your own content templates

Jig embeds templates for all the kinds of content that it knows how to scaffold.
To customize them, you'd dump them to disk and then edit as you like.

```console
jig templates dump ~/.config/jig/templates
```

Any template found in your directory takes precedence over the embedded default, and any template you don't override falls back to the embedded version, so you only need to include the files you want to change.

Two rules govern how a template becomes a file in the module:

* A file ending in `.tmpl` is rendered with Go's [text/template](https://pkg.go.dev/text/template) and written with the suffix stripped, so `README.md.tmpl` becomes `README.md`.
  Every other file is copied byte-for-byte.
  This is what lets a GitHub Actions workflow, which uses `{% raw %}{{ ... }}{% endraw %}` for its own purposes, sit in a template tree unescaped: leave the `.tmpl` suffix off and it's copied as-is.
* The `module/` directory of the template tree mirrors the generated module exactly.
  There's no mapping in Jig's source, so you can add files Jig knows nothing about.
  Drop `module/.github/workflows/ci.yml` into your template directory and every module you scaffold gets it.

`metadata.json` and `jig.toml` are the exceptions: Jig always generates those itself and ignores (with a warning) any copy in a template tree.

To tell Jig where your templates live, use any of the following, in order of precedence:

* the `--template-dir` (`-t`) flag on `jig new`,
* the `JIG_TEMPLATE_DIR` environment variable, or
* the `template_dir` key in your Jig config file.

When something doesn't render the way you expect, `jig templates resolve` shows exactly where a template name is being loaded from and every path Jig checked on the way:

```console
$ jig templates resolve class/class.pp
no external template directory configured; using embedded templates only
  looking for templates/class/class.pp.tmpl (embedded) ... found
resolved class/class.pp to embedded template templates/class/class.pp.tmpl (rendered with text/template)
```

### Sharing templates from a git repository

A directory on disk works for one person.
For a team, point Jig at a git repository instead and everyone scaffolds from the same source without keeping a checkout at the same local path:

```console
jig new module --template-url 'ssh://git@my.git.server/jig_templates.git' --template-ref main mymodule
```

Jig makes a shallow clone into a temporary directory, uses it exactly like a `--template-dir`, and deletes the clone afterwards.
The repository layout is the same as a dumped template directory.
It then records the URL, ref, and commit in the module's `jig.toml` under `[template]`, so later `jig new class` and similar commands inside that module use the same templates with no flags at all.
An explicit `--template-dir` or `--template-url` overrides the recorded values.

ssh URLs authenticate through your running ssh-agent; https URLs are anonymous only.
On first contact with an unknown host Jig shows the key fingerprint and asks, like OpenSSH does.
In CI, pass `--ssh-accept-new` (or set `ssh_accept_new = true` in your config, or export `JIG_SSH_ACCEPT_NEW=true`) to accept unknown hosts automatically.
A host key that has _changed_ always fails with no override; if a server legitimately rotated its key, run `ssh-keygen -R <host>` and try again.

## Refreshing a module from its templates

When you change a template, `jig renew` re-renders the affected files in an existing module and overwrites them, so a change to (say) your standard `Gemfile` can be rolled out across many modules without hand-editing each one.

It only touches files matching the `[renew]` allowlist in the module's `jig.toml`, and that list is empty by default, so nothing can be overwritten until the module opts in:

```toml
[renew]
paths = [".github/**", "Gemfile", "Rakefile", "spec/spec_helper.rb"]
```

Patterns are gitignore-style globs relative to the module root.
Allowlisted files whose rendered content differs are overwritten, files that already match are left alone, and allowlisted files the module doesn't have yet are created.
`metadata.json` and `jig.toml` are never renewed.

Run it with `--dry-run` first to see a diff of every file that would change without writing anything:

```console
jig renew --dry-run
jig renew
```

The template source resolves the same way as for `jig new`: flags first, then `[template]` in `jig.toml` (re-fetching the latest commit of the recorded ref), then `template_dir` from your config.
After a successful renew from a remote repository, Jig rewrites `jig.toml` with the commit it fetched, so hand-written comments in that file don't survive.

If you maintain many modules with [ModuleSync](modulesync.html), note the difference: `jig renew` is Jig's own template-driven refresh of one module, while `jig msync update` runs ModuleSync.
Pick one mechanism per file; having both manage the same `Gemfile` will end in a tug of war.
{: .tip }

## Running the Ruby-backed commands

Three commands wrap the `bundle exec` tooling described elsewhere in this guide, so you can use one CLI for everything:

| Command | Runs |
|---------|------|
| `jig validate` | `rake validate`, `rake lint`, and `rake rubocop`, each as its own invocation, stopping at the first failure. `-s`, `-l`, and `-r` select a subset. |
| `jig test unit` | `rake spec`, or `rake parallel_spec` with `--parallel`. |
| `jig msync` | `msync` with whatever arguments you pass, for example `jig msync update`. |

Arguments after `--` are passed through verbatim to the underlying command.
Because these shell out to Bundler, they need the module's gems installed (`bundle install`) just as the direct commands do.

If you'd rather not maintain a Ruby toolchain on the host, set `type = "voxbox"` in the `[runner]` section of your config file (or export `JIG_RUNNER_TYPE=voxbox`).
Jig then runs the same three commands inside the [VoxBox](voxbox.html) container, mounting the module at `/repo`, so the only host dependency is Docker or Podman.
This is the most practical route on Windows, where a system-wide Bundler install is awkward.

## Migrate an existing module to Jig

`jig convert` brings an existing module onto the toolchain that Jig's other commands expect.
Run it from the module's root directory and it overwrites `Gemfile`, `Rakefile`, and `spec/spec_helper.rb` with the same templates `jig new module` uses, creating `spec/` if needed:

```console
$ jig convert
convert successful: Gemfile, Rakefile, spec/spec_helper.rb
```

It works on PDK-generated and hand-maintained modules alike, including modules old enough to predate `metadata.json`.
Before it touches the three files above, it looks at the module's `metadata.json`:

* **Missing.** Jig creates it, and writes a `jig.toml` as well if the module doesn't have one.
  If a Puppet 3-era `Modulefile` is present, its `name`, `version`, `author`, `license`, `summary`, `source`, and `dependency` lines pre-fill the new file, and the `Modulefile` is left in place with a warning that you can delete it.
  Otherwise Jig runs the same interview as `jig new module`, taking the module name from the directory name (`puppet-nftables` gives `nftables`).
  Pass `--skip-interview` (`-i`) together with the `-u`, `-a`, `-l`, `-s`, and `-S` flags to answer non-interactively; a flag wins over the `Modulefile`, which wins over the defaults in your config file.
* **Present but not valid JSON.** Jig prints the parse error and stops without changing anything.
* **Present but incomplete.** Jig fills in a default `version` (`0.1.0`) and empty `dependencies`, `requirements`, `operatingsystem_support`, and `tags` lists where they're missing, warns about anything else that fails validation (a missing `author` or `source`, say), and never overwrites a value that's already there.
  Running it a second time changes nothing.
* **Present and valid.** Left alone.

Add `--dry-run` to see what would be created or overwritten without writing anything.
Older Jig releases refuse to run without a `metadata.json`; if you see `metadata.json not found`, upgrade Jig.

Unlike `jig renew`, it always uses Jig's embedded templates, ignoring `--template-dir` and the module's `jig.toml`, and it needs no allowlist.

If you're coming from the PDK, the [migration page](migrating.html) maps each `pdk` command to its Jig or `bundle exec` equivalent.

## Alternative scaffolding solutions

Jig is the only scaffolding tool we have currently tested.
If you'd like to experiment, there are other options available.

* [Regent](https://github.com/ffquintella/regent) is a high-performance, modern implementation of PDK features in Rust. It uses the embedded Artichoke Ruby runtime for all Ruby execution.
* [PCT](https://github.com/jay7x/pct) is an experimental pluggable content templating system. It's designed so that rather than a single set of templates, each component is a separate template. This means that you could choose to use one author's _module_ template, but a different author's _class_ template, and yet another author's template for adding GitLab CI pipelines.
