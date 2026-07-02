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
│   └── common.yaml
├── examples
├── files
├── Gemfile
├── hiera.yaml
├── manifests
│   └── init.pp
├── metadata.json
├── Rakefile
├── README.md
├── spec
│   ├── classes
│   │   └── init_spec.rb
│   ├── default_facts.yml
│   └── spec_helper.rb
├── tasks
└── templates

9 directories, 11 files
```

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
```

## Maintaining your own content templates

Jig embeds templates for all the kinds of content that it knows how to scaffold.
To customize them, you'd dump them to disk and then edit as you like.

```console
jig templates dump ~/.config/jig/templates
```

Any template found in your directory takes precedence over the embedded default, and any template you don't override falls back to the embedded version, so you only need to include the files you want to change.

To tell Jig where your templates live, use either of the following:

* the `--template-dir` (`-t`) flag on `jig new`, which takes precedence, or
* the `template_dir` key in your Jig config file.

-----

## Alternative scaffolding solutions

Jig is the only scaffolding tool we have currently tested.
If you'd like to experiment, there are other options available.

* [Regent](https://github.com/ffquintella/regent) is a high-performance, modern implementation of PDK features in Rust. It uses the embedded Artichoke Ruby runtime for all Ruby execution.
* [PCT](https://github.com/jay7x/pct) is an experimental pluggable content templating system. It's designed so that rather than a single set of templates, each component is a separate template. This means that you could choose to use one author's _module_ template, but a different author's _class_ template, and yet another author's template for adding GitLab CI pipelines.
