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

This will update the `metadata.json`, build the package, and then publish it.

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
