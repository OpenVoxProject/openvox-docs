---
layout: default
title: "Module CI with GitHub Actions"
---

This page assumes your module already has the Vox Pupuli test suite wired in, so that `bundle exec rake validate lint` works locally.
If it doesn't yet, either [set up `voxpupuli-test`](setup.html#setting-up-the-vox-pupuli-test-suite) by hand, or let Jig do it: `jig new module` for a new module, or [`jig convert`](https://github.com/voxpupuli/jig/blob/main/docs/commands/convert.md) from the root of an existing one, which overwrites `Gemfile`, `Rakefile`, and `spec/spec_helper.rb` with the same templates `jig new module` uses.

With that in place, the next step is to run the same tasks on every push and pull request.
Vox Pupuli publishes a set of [reusable GitHub Actions workflows](https://github.com/voxpupuli/gha-puppet) (`gha-puppet`) that do exactly that.
Nearly every module in the Vox Pupuli namespace uses them, and you can call them from your own repository with a workflow file of about ten lines.

This page covers what the workflow expects to find in your module, how to call it, and what to do instead if you only want a quick syntax check.

If you use GitLab CI or another runner, see [Using VoxBox in CI](voxbox.html) instead.
{: .tip }

## What the workflow expects

`gha-puppet` doesn't install tools or make assumptions about your module.
It checks out your repository, runs `bundle install`, and then calls the same rake tasks you run locally.
That means your module needs the same three files that the rest of the DevKit relies on:

1. A `Gemfile` with a `test` group containing `voxpupuli-test` and `puppet_metadata`, and an `openvox` gem line that reads its version from the environment.
   The workflow sets `OPENVOX_GEM_VERSION` to pick the release under test, so this is what lets it build a version matrix.

   ```ruby
   source ENV['GEM_SOURCE'] || 'https://rubygems.org'

   group :test do
     gem 'voxpupuli-test', '~> 14.0',  :require => false
     gem 'puppet_metadata', '~> 6.1',  :require => false
   end

   group :system_tests do
     gem 'voxpupuli-acceptance', '~> 4.4',  :require => false
   end

   group :release do
     gem 'voxpupuli-release', '~> 5.3',  :require => false
   end

   gem 'rake', :require => false

   gem 'openvox', ENV.fetch('OPENVOX_GEM_VERSION', [">= 7", "< 9"]), :require => false, :groups => [:test]
   ```

2. A `Rakefile` that loads the `voxpupuli-test` tasks.
   The `LoadError` rescues let the same file work when only some gem groups are installed, which is how CI keeps the static-check job small.

   ```ruby
   begin
     require 'voxpupuli/test/rake'
   rescue LoadError
     # only available if gem group test is installed
   end

   begin
     require 'voxpupuli/acceptance/rake'
   rescue LoadError
     # only available if gem group acceptance is installed
   end
   ```

3. A `metadata.json` with a `requirements` entry for `openvox` (or `puppet`; the tooling accepts either name) and, if you plan to add acceptance tests later, an `operatingsystem_support` list.
   The workflow reads these to decide which OpenVox and Ruby versions to test against.
   See the [module metadata reference](/openvox/latest/modules_metadata.html) for the full format.

If you scaffolded your module with [`jig new module`](jig.html#creating-a-new-module), you already have all three.
If you ran `jig convert` on an existing module, you have the first two.
It works on PDK-generated and hand-maintained modules alike, but it insists on `metadata.json` already existing; if your module predates `metadata.json` and still carries a `Modulefile` (support for which was removed in Puppet 4), write `metadata.json` first, then run `jig convert`.

## Adding the workflow

Create `.github/workflows/ci.yml` in your module:

```yaml
name: CI

on:
  pull_request: {}
  push:
    branches:
      - main

concurrency:
  group: ${{ github.ref_name }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  puppet:
    name: Puppet
    uses: voxpupuli/gha-puppet/.github/workflows/basic.yml@v4
    with:
      # Set to false if your module doesn't use Rubocop.
      rubocop: true
```

Commit it, push, and open a pull request. You'll see three jobs under the **Puppet** heading:

| Job | What it runs |
|-----|--------------|
| **Static validations** | `bundle exec rake validate lint check`, then `rake rubocop` (unless disabled), then `metadata2gha` to build the test matrix from `metadata.json` |
| **`<version>` (Ruby `<version>`)** | One job per supported OpenVox and Ruby combination, each running `bundle exec rake parallel_spec` |
| **Test suite** | A summary job that passes only if every job above passed. Use this one as your required status check in branch protection. |

The reusable workflow accepts a few inputs under `with:`:

| Input | Default | Purpose |
|-------|---------|---------|
| `rubocop` | `true` | Run the `rubocop` task. Set to `false` if your module has no Ruby code or doesn't inherit the Vox Pupuli Rubocop config. |
| `working-directory` | `.` | Path to the module when it lives in a subdirectory, such as a control repository's `site-modules/`. |
| `additional_packages` | `''` | Space-separated apt packages to install before the tests run, for gems with native extensions. |
| `timeout_minutes` | `45` | Cancel any job that runs longer than this. |
| `unit_runs_on` | `ubuntu-24.04` | Runner label for the unit-test jobs, for self-hosted runners. |

The `gha-puppet` [README](https://github.com/voxpupuli/gha-puppet#readme) documents the full list, including the release workflow that Vox Pupuli uses to publish to the Forge.

## Running the same checks locally

Everything the workflow does maps onto a rake task, so you can reproduce a CI failure without pushing:

```console
bundle exec rake validate lint check rubocop
bundle exec rake parallel_spec
```

Or run them all at once with `bundle exec rake test`.
The pages on [linting](linting.html) and [unit testing](unit_testing.html) explain what each task checks and how to configure it.

To test against a specific OpenVox release the way the matrix does, set the same environment variable the workflow uses:

```console
OPENVOX_GEM_VERSION='~> 8.0' bundle install
bundle exec rake parallel_spec
```

## Adding acceptance tests

When you're ready to run your module against real operating systems, switch `basic.yml` to `beaker.yml` in the `uses:` line.
The beaker workflow runs everything above and then adds a job per platform listed in your `metadata.json`, using Docker on the GitHub-hosted runner.
The [acceptance testing guide](acceptance_testing.html#running-in-ci) covers what the tests themselves look like.

## If you only want a syntax check

The reusable workflow is the right tool for a module you maintain and publish.
For a one-off repository, or a module you're only validating before applying it with `puppet apply`, you might want something lighter that doesn't require adding a `Gemfile` and `Rakefile`.

This workflow installs OpenVox as a gem and runs the parser and linter directly:

```yaml
name: Validate

on:
  pull_request: {}
  push:
    branches:
      - main

permissions:
  contents: read

jobs:
  validate:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
      - run: gem install openvox puppet-lint
      - name: Check syntax
        run: find manifests -name '*.pp' -print0 | xargs -0 puppet parser validate
      - name: Lint
        run: puppet-lint manifests
```

Be aware of what this doesn't catch.
`puppet parser validate` only checks that each file parses.
It won't notice a class that doesn't exist, a function from a module you forgot to declare as a dependency, or a template that renders garbage, because none of that is resolved until a catalog is compiled.
The `voxpupuli-test` unit tests catch all of those, which is why the reusable workflow is worth the extra setup as soon as the module matters.

Neither workflow applies your manifest to a machine.
If that's what you want to verify, [acceptance tests](acceptance_testing.html) are the supported way to do it.
{: .tip }

## Troubleshooting

### `Could not locate Gemfile or .bundle/ directory`

The **Static validations** job fails on its first step, and every unit job shows as skipped:

```text
Run bundle exec rake validate lint check
Could not locate Gemfile or .bundle/ directory
Error: Process completed with exit code 10.
```

Your repository has no `Gemfile` at the path the workflow is looking at.
Add one as described in [What the workflow expects](#what-the-workflow-expects), or set `working-directory` if the module lives in a subdirectory.

### `unit → skipped [required to succeed]`

The **Test suite** job reports the unit matrix as skipped.
This is never the root cause; it means the **Static validations** job failed before `metadata2gha` could produce a matrix.
Open that job's log and fix the first error you see.

### `metadata2gha` fails or produces an empty matrix

`metadata.json` is missing, isn't valid JSON, or has no `requirements` entry for `openvox` or `puppet`.
Run `bundle exec rake metadata_lint` locally to see the specific complaint.
