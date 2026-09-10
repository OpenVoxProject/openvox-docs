---
layout: default
title: "Publishing a Module"
---

One of the major benefits of the Puppet and OpenVox ecosystem is the large number of community maintained modules available for use.
We encourage you to contribute and share your own.

There are three common ways to publish Puppet modules to the Forge.
Each of them will require a Forge account; if needed you can [sign up now](https://forge.puppet.com/signup).

## Manual publishing on the web

This technique will use Jig again; it turns out that maintaining a Puppet module is more than just scaffolding.
First we'll build the module package.
From the root of your module's directory run:

```console
$ jig build
built /Users/ben.ford/Projects/demo/pkg/binford2k-demo-0.1.0.tar.gz
```

Now browse to the [Forge upload page](https://forge.puppet.com/upload), choose the generated file and upload it.
This will create the module listing if required and add a module release to it.

### What gets packaged

Jig validates `metadata.json` before building; errors abort the build and warnings are printed.

By default the package contains only the files the [Puppet module specification](https://github.com/puppetlabs/puppet-specifications/pull/157) allows in a published module: `manifests/`, `lib/`, `data/`, `metadata.json`, and so on.
Development files like `Gemfile`, `spec/`, and dotfiles stay out with no configuration at all.

Jig does not read `.pdkignore` or `.pmtignore`.
If you migrated from the PDK, `jig build` will warn about any leftover ignore file and suggest removing it; for most modules that's all you need to do, since the allowlist already excludes what those files used to exclude.
`.gitignore` is left alone because it belongs to git, not the build.

To ship a file the specification doesn't know about, or to get the old "everything except" behavior back, add a `[build]` section to the module's `jig.toml`:

```toml
# Extend the allowlist with extra files (recommended)
[build]
action     = "deny"
exceptions = ["/mycustomfile.txt"]
```

```toml
# Or package everything except the listed paths, the way .pdkignore used to
[build]
action     = "allow"
exceptions = ["/spec/**", "/Gemfile"]
```

In both modes `pkg/`, `.git/`, `jig.toml` itself, and `.gitkeep` markers are never packaged.

## Pushing a release from the command line

If you'd like to streamline your workflow, you can push a release directly using Jig.
First you'll need to configure it with a Forge API token.
Generate your token [on the Forge](https://forge.puppet.com/profile/api-keys), choosing a reasonable lifespan.
You'll need to regenerate this token each time it expires.

Add the token to your Jig config file at `~/.config/jig/config.toml`

```toml
forge_username = "your-forge-username"
forge_token    = "your-forge-token"
```

Now that it's configured, you can publish a new version of your module.

```console
jig release --version x.y.z
```

This validates the metadata, writes the new version into `metadata.json`, builds the package, and then publishes it.
The version must be plain semver (`MAJOR.MINOR.PATCH`).
Pass `--token` to supply the Forge token on the command line instead of from the config file, and `--skip-validation`, `--skip-build`, or `--skip-publish` to leave out a step; with `--skip-build`, Jig expects the archive to already exist under `pkg/`.

## Scripting a release

Vox Pupuli also maintains a release tooling suite, suitable for CI integration.
It's intended primarily to allow module maintenance via repository actions so that a team can collaborate effectively.
For example, GitHub Actions could test, release, and publish on merges to a `release` branch or the like.

It includes several rake tasks which can be used for building and publishing a module, either on the command line or in your own scripts.

First add the `voxpupuli-release` Gem to your `Gemfile` and `bundle install` it.

```console
gem 'voxpupuli-release', git: 'https://github.com/voxpupuli/voxpupuli-release-gem'
```

Then add it to the top of your `Rakefile`:

```console
require 'voxpupuli-release'
```

Then you should set up your Forge API token.
You can use the same token you generated for Jig, or you can create one specifically for these tasks.

If you're going to use the token in a pipeline, you should generate one specifically for it so that you can revoke it if needed without disrupting other work.
{: .tip }

Add your token to `~/.puppetforge.yml`:

```yaml
---
api_key: myAPIkey
```

Then you can build and publish the module with:

```console
bundle exec rake module:build
bundle exec rake module:push
```

If you'd like, you can [read more](vox_pupuli_workflow.html) about the whole Vox Pupuli module maintenance workflow.
