---
layout: default
title: "Components of the DevKit"
---

The Vox Pupuli developer toolkit is spread amongst many Ruby gems and other tools.
Most will be automatically pulled in via Bundler and the `Gemfile`, and some of the main ones will be listed at the bottom of this page for convenience.
We'll focus on the tools that you may want to be aware of and install or use directly.

* [Jig](https://github.com/voxpupuli/jig) is useful for scaffolding content for new and existing modules.
  All content it generates includes the appropriate barebones unit tests ready for you to fill out.
  It can also publish modules to the Puppet Forge.
  See [Scaffolding New Content with Jig](jig.html) for installation and usage.
* [ModuleSync](https://github.com/voxpupuli/modulesync) helps maintain a portfolio of many modules at once.
  It does this by maintaining both common static files (like contributing guides, licenses, or testing boilerplate) as well as templated files like `metadata.json` across multiple module repositories.
  This allows you to keep them all in a consistent state with minimal fuss.
* [VoxBox](https://github.com/voxpupuli/container-voxbox) is a container that lets you run many of the developer
tools without installing anything but a container runtime like Docker or Podman.
  See [Using VoxBox in CI](voxbox.html) for how to run it locally and in GitLab pipelines.
* [OnceOver](https://github.com/voxpupuli/onceover) is used for basic validation of your control repository.
  It can sometimes be insurmountable to get proper unit testing for every single module you use, especially when most of them are maintained by others.
  OnceOver will do basic `it_compiles` spec tests for each of your profile classes, giving you some confidence in them.
* [Beaker](https://github.com/voxpupuli/beaker) is the acceptance test framework.
  Where unit tests inspect a compiled catalog, Beaker spins up real nodes (using Docker by default), applies your manifests for real, and asserts on the actual results.
  You'll usually drive it through [`voxpupuli-acceptance`](https://github.com/voxpupuli/voxpupuli-acceptance), which wires Beaker into the standard Vox Pupuli test suite.
  See [Acceptance Testing with Beaker](acceptance_testing.html) for setup and usage.
* [Catalog Diff](https://github.com/voxpupuli/puppet-catalog_diff) and [Viewer](https://github.com/voxpupuli/puppet-catalog-diff-viewer) show you differences between two catalogs.
  This can be used for impact analysis of upcoming code changes or infrastructure updates.
  You can see a [quick demo of the graphical interface](http://voxpupuli.org/puppet-catalog-diff-viewer) by choosing the "Demo 1" report.


## `voxpupuli-test` Test Suite

When you [set up the `voxpupuli-test` suite](setup.html#setting-up-the-vox-pupuli-test-suite), this is a quick overview of the tooling that becomes accessible.
The individual pages in this guide will have more information about how to use each of them.

* [`voxpupuli-test`](https://github.com/voxpupuli/voxpupuli-test) is the suite itself. It pulls in other tools as dependencies.
* [`rspec-puppet`](https://github.com/puppetlabs/rspec-puppet) is the standard unit testing framework for Puppet and OpenVox.
It allows you to assert certain expectations about your compiled catalog, such as whether it does or does not contain certain resources with specific parameters.
Tests are written in Ruby, which allows tests to be constructed programmatically as needed.
  * [`facterdb`](https://github.com/voxpupuli/facterdb) is a database of representative facts for various platforms. This will let you test your module as if it were being applied on each platform.
  * [`rspec-puppet-facts`](https://github.com/voxpupuli/rspec-puppet-facts) uses `facterdb` to loop over all supported platforms from `metadata.json`.
* [`puppet-syntax`](https://github.com/voxpupuli/puppet-syntax/) will syntax check Puppet manifests, `.erb` and `.epp` templates, and Hiera data files.
* Linters enforce consistency in code and other files. The suite includes several types of linters.
  * [`puppet-lint`](https://github.com/puppetlabs/puppet-lint) lints Puppet manifests against the [OpenVox Language Style Guide](/openvox/latest/style_guide.html).
    * [`voxpupuli-puppet-lint-plugins`](https://github.com/voxpupuli/voxpupuli-puppet-lint-plugins) are various plugins that enforce various optional extensions to the style guide.
    See the [`.gemspec`](https://github.com/voxpupuli/voxpupuli-puppet-lint-plugins/blob/master/voxpupuli-puppet-lint-plugins.gemspec) for a list of the enabled checks.
    * [`metadata-json-lint`](https://github.com/voxpupuli/metadata-json-lint) validates the module's `metadata.json` file for maximum compatibility.
    * [`rubocop`](https://rubocop.org) is a Ruby static code checker (linter) and formatter based on the community-driven [Ruby Style Guide](https://rubystyle.guide/).
* [`openvox-strings`](https://github.com/voxpupuli/openvox-strings) automatically generates references for Puppet code and extensions.
* [`parallel_tests`](https://github.com/grosser/parallel_tests) speed up your tests by safely running them in parallel.
* [`puppet_fixtures`](https://github.com/voxpupuli/puppet_fixtures) manages fixtures for your tests.
Many times modules will depend on others for their functionality, and that means that dependencies need to be installed for testing. These are called _fixtures_.
