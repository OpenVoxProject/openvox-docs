---
layout: default
title: "Smoke Testing Your Control Repo"
---

We don't want to be responsible for a full testing framework for each module we use in our infrastructure, including all community modules.
But we also want to at least validate that they all _work_ the way we're using them before deploying into production.

For this we use Onceover, which bills itself as
> The gateway drug to automated infrastructure testing with Puppet!

This is a tool to automatically run basic tests on an entire Puppet control repository.
It will parse the `Puppetfile`, `environment.conf`, and others -- then run basic validations to ensure that each role or profile class will compile with the facts and data your environment provides.

## Setup and Configuration

Like many tools in the Vox Pupuli ecosystem, Onceover is shipped as a gem.
This means that you'll run it with Bundler.

In the root of your control repository:

Add onceover to your Gemfile:

```ruby
gem 'onceover'
```

Install and initialize the boilerplate:

```console
bundle install
bundle exec onceover init
```

Then edit the configuration file at `spec/onceover.yaml`.
The following settings will test all role classes for specific versions of Debian, Ubuntu, and Solaris machines.
It will also make sure that the core vendored modules from the `puppet-agent` package are available.

```yaml
classes:
  - /^role::/

nodes:
  - Debian-10-amd64
  - Ubuntu-20.04-64
  - solaris-11.2-sparc-64

test_matrix:
  - all_nodes:
      classes: 'all_classes'
      tests: 'spec'
opts:
  auto_vendored: true
```

## Running the Tests

When you run tests, Onceover will use `r10k` to temporarily install all the modules specified in your `Puppetfile` as fixtures
and then run basic `it_compiles` spec tests on each class matching the `classes` setting in your configuration.

```console
bundle exec onceover run spec
```

## More

This is just the most basic usage of Onceover.
If needed, you can add your own custom spec tests, mock functions, generate custom factsets, and more.
See the [project's own documentation](https://github.com/voxpupuli/onceover) for all the details.
