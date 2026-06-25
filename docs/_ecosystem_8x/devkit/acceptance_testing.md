---
layout: default
title: "Acceptance Testing with Beaker"
---

Unit testing and knowing that all the individual bits compile the way we expect to is critical, especially for preventing regressions as we continue maintenance on a module.
But nothing compares to knowing what the module actually _does_ when you enforce it on a node.

For example, knowing that a class includes a [`package`](/openvox/8.x/type.html#package) resource with the expected package name is one thing.
But that doesn't help if the OS changes the name of the package in newer releases.

Acceptance tests close that gap.
Where a [unit test](unit_testing.html) inspects a catalog (the set of resources Puppet compiles for a node) without ever applying it, an acceptance test spins up a real node, applies your manifest for real, and then asserts on the actual results.

Vox Pupuli uses an acceptance test framework known as [Beaker](https://github.com/voxpupuli/beaker).
It will deploy various infrastructure configurations using various hypervisors (the tools that build and run the test machines), defaulting to [Docker](https://www.docker.com/).
In other words, it will deploy a server and one or more agent nodes and then validate that the module classes actually do what they claim when they're enforced.

You won't drive raw Beaker directly.
Instead you'll use [`voxpupuli-acceptance`](https://github.com/voxpupuli/voxpupuli-acceptance), a thin gem (a packaged Ruby library) that wires Beaker into the standard Vox Pupuli test suite and removes most of the boilerplate.

## Prerequisites

Acceptance tests are heavier than unit tests because they build real machines, so there's a little more to set up.

First, you need a hypervisor.
Beaker defaults to Docker, which is the easiest way to get started, so install it and make sure your user can run containers.
[Podman](https://podman.io/), [Vagrant](https://www.vagrantup.com/), and [libvirt](https://libvirt.org/) are also supported if you prefer them.

If you're running locally on macOS, two extra wrinkles come up. Neither affects Linux CI runners, which already provide the standard socket and architecture.

**The Docker socket.**
Docker Desktop puts its socket at `~/.docker/run/docker.sock`, but Beaker looks for `/var/run/docker.sock`.
Either turn on _Allow the default Docker socket to be used_ in Docker Desktop's settings, or export `DOCKER_HOST=unix://$HOME/.docker/run/docker.sock`.

**The architecture.**
Apple Silicon Macs are arm64, but many Vox Pupuli Docker setfile images are currently `linux/amd64` (x86_64) only, so they don't match your machine. (Intel Macs are x86_64 and run them natively, with none of these caveats.)
Docker Desktop can run the mismatched images under emulation, but emulated acceptance runs are slower and can be more fragile than a native run such as Linux CI.
If Docker reports an image platform mismatch, export `DOCKER_DEFAULT_PLATFORM=linux/amd64`, pull the base image once with that platform selected, and retry.

Second, you need a current Ruby.
The Ruby that ships with macOS and some Linux distributions is too old, and using it makes `bundle install` fail with a confusing dependency error rather than a clear "your Ruby is too old" message.
Most people install and select Ruby with a version manager such as [rbenv](https://github.com/rbenv/rbenv), [rvm](https://rvm.io/), or [mise](https://mise.jdx.dev/).
Install a 3.x Ruby, then run `ruby --version` in the module directory and confirm it reports 3.x before you go further; the [DevKit setup guide](setup.html) covers this in more detail.

Finally, you need the acceptance gems installed.
A module's `Gemfile` sorts its gems into named groups so that, for example, continuous integration can install only what each job needs.
The Beaker gems live in a group called `system_tests`, and some setups skip that group by default to keep installs lean.
This command tells [Bundler](https://bundler.io/) to install everything _except_ the `development` and `release` groups, which keeps `system_tests` (and the regular `test` group) in place:

```console
bundle config set --local without 'development release'
bundle install
```

The `--local` flag writes that choice to `.bundle/config` inside the module, so you only have to set it once.
If the whole `bundle` / `bundle exec` workflow is new to you, the [DevKit setup guide](setup.html) walks through it from the start.

## Setting up the framework

Most modules scaffolded with the Vox Pupuli tooling already have this wired up, so check before you add anything.
If it's missing, three small pieces connect a module to the framework.

Add the gem to your `Gemfile`, in the `system_tests` group so it only installs when you're running acceptance tests:

```ruby
group :system_tests do
  gem 'voxpupuli-acceptance', '~> 4.4', require: false
end
```

Configure the helper in `spec/spec_helper_acceptance.rb`:

```ruby
require 'voxpupuli/acceptance/spec_helper_acceptance'

configure_beaker
```

And import the rake tasks (Rake is Ruby's task runner) in your `Rakefile`:

```ruby
require 'voxpupuli/acceptance/rake'
```

That's it.
The `configure_beaker` call handles installing OpenVox, installing your module and its dependencies, and preparing each node before your tests run.

## Anatomy of an acceptance test

Acceptance tests live in `spec/acceptance/` and read very much like the [`rspec-puppet`](https://rspec-puppet.com/) tests you already know.
The difference is that instead of inspecting a compiled catalog, you apply a manifest to a live node and then assert against its real state.

A test applies a manifest with [`apply_manifest`](https://www.rubydoc.info/gems/beaker_puppet_helpers/BeakerPuppetHelpers/DSL), one of the Beaker DSL helper methods that `voxpupuli-acceptance` makes available in your specs (alongside `fact_on`, `install_package`, and others).
The standard pattern is to apply the manifest _twice_.
The first run uses `catch_failures: true` to assert the apply succeeds.
The second run uses `catch_changes: true` to assert that nothing changed.

That second run is the heart of acceptance testing, because it proves _idempotency_.
A manifest is idempotent when applying it more than once is safe: the first run brings the system to the desired state, and every run after that makes no changes because the system already matches.
Idempotency is a core property of well-written Puppet code, and a manifest that keeps making changes on every run is a bug.
Catching that here is one of the most valuable things an acceptance test does.

Once the manifest is applied, you assert against the real node using the [`serverspec`](https://serverspec.org/) matchers such as `package`, `service`, and `port`.
A typical test for a `chrony` class looks like this:

```ruby
require 'spec_helper_acceptance'

describe 'chrony' do
  it 'works idempotently with no errors' do
    pp = <<-PUPPET
    class { 'chrony':
      # These flags let chrony run in a container: -x stops it from
      # controlling the system clock, and -F 0 disables its seccomp
      # system-call filter.
      options => '-F 0 -x',
    }
    PUPPET

    apply_manifest(pp, catch_failures: true)
    apply_manifest(pp, catch_changes: true)
  end

  describe package('chrony') do
    it { is_expected.to be_installed }
  end

  # The service is named chronyd on RHEL-family systems but chrony on
  # Debian-family ones, so choose the name from a fact about the node.
  service_name = fact('os.family') == 'RedHat' ? 'chronyd' : 'chrony'

  describe service(service_name) do
    it { is_expected.to be_running }
    it { is_expected.to be_enabled }
  end
end
```

This mirrors the real [`puppet-chrony`](https://github.com/voxpupuli/puppet-chrony/blob/master/spec/acceptance/class_spec.rb) acceptance test.
[`puppet-systemd`](https://github.com/voxpupuli/puppet-systemd/tree/master/spec/acceptance) is a good reference once you want to see a larger suite.

The framework also ships shared examples as shortcuts for the most common patterns.
The `an idempotent resource` example wraps that same two-run idempotency check, and `the example` applies a manifest straight from your module's `examples/` directory:

```ruby
describe 'chrony' do
  it_behaves_like 'an idempotent resource' do
    let(:manifest) { "class { 'chrony': options => '-F 0 -x' }" }
  end
end

describe 'my example' do
  it_behaves_like 'the example', 'my_example.pp'
end
```

## Choosing a platform to test

A [_setfile_](https://github.com/voxpupuli/beaker-hostgenerator) describes which operating system and release Beaker should build for a given run.
You don't usually write these by hand; the supported set is derived from your module's `metadata.json`.

List the setfiles available to your module with:

```console
bundle exec puppet-metadata setfiles
```

(You may also see the older `bundle exec setfiles` command, which still works but now just forwards to `puppet-metadata setfiles`.)

You then select one for a run with the `BEAKER_SETFILE` environment variable, for example `ubuntu2404-64` or `almalinux9-64`.

## Running the tests

The entry point is a single rake task:

```console
BEAKER_SETFILE=ubuntu2404-64 bundle exec rake beaker
```

That command will build the node, install OpenVox and your module, run every test in `spec/acceptance/`, and tear the node back down.

To run just one test file while you're iterating, call `rspec` directly:

```console
BEAKER_SETFILE=ubuntu2404-64 bundle exec rspec spec/acceptance/chrony_spec.rb
```

A handful of environment variables control the run.
The ones you'll use most are:

| Variable | What it does |
|----------|--------------|
| `BEAKER_SETFILE` | Selects the OS/release to test, for example `ubuntu2404-64`. |
| `BEAKER_HYPERVISOR` | Picks the backend. Defaults to `docker`; `vagrant` and `vagrant_libvirt` are common alternatives. |
| `BEAKER_PUPPET_COLLECTION` | Chooses which collection to install, such as `openvox8` for OpenVox or `puppet8` for upstream Puppet. |
| `BEAKER_DESTROY` | Controls cleanup. Set to `no` to keep the node after the run, or `onpass` to only destroy it when the tests pass. |
| `BEAKER_PROVISION` | Set to `no` to reuse an existing node instead of building a fresh one. |
| `BEAKER_FACTER_<name>` | Injects a fact, available in your manifest and tests as `fact('<name>')`. |

## Debugging a failure

When a test fails, the most useful trick is to stop Beaker from cleaning up so you can inspect the node yourself:

```console
BEAKER_DESTROY=no BEAKER_SETFILE=ubuntu2404-64 bundle exec rake beaker
```

The node stays running after the test finishes, and Beaker prints how to connect to it.
For the default Docker hypervisor you can `docker ps` to find the container and `docker exec` into it to poke at the real filesystem, services, and logs.

When you've found the problem, pair `BEAKER_PROVISION=no` with `BEAKER_DESTROY=no` to re-run your tests against that same node without paying the cost of rebuilding it each time.

## Running in CI

The same `rake beaker` command runs unchanged in continuous integration.
GitHub-hosted runners already have Docker, so a job only needs to install the gems (including the `system_tests` group) and then run the task with the environment variables set:

```yaml
- name: Run acceptance tests
  run: bundle exec rake beaker
  env:
    BEAKER_HYPERVISOR: docker
    BEAKER_PUPPET_COLLECTION: openvox8
    BEAKER_SETFILE: almalinux9-64
```

Start with a single setfile so failures are easy to read, then grow the test matrix (the set of platforms you run against) to cover everything in your `metadata.json` once it's green.

Most Vox Pupuli modules don't hand-write this job.
Instead they call the shared [`gha-puppet`](https://github.com/voxpupuli/gha-puppet) reusable workflow, which builds the platform matrix from your `metadata.json` automatically.
See [puppet-chrony's `ci.yml`](https://github.com/voxpupuli/puppet-chrony/blob/master/.github/workflows/ci.yml) for a complete, working example.
That file carries a "do not edit" header because it's maintained by [modulesync](https://voxpupuli.org/docs/updating-files-managed-with-modulesync/), which keeps shared files like CI workflows consistent across every Vox Pupuli module, so in such a repo you'd update the synced template, not the module's copy.

## Customizing the nodes

If your module needs something on the node before your manifest runs, such as an extra repository or package, you have two options.

For simple cases, drop a manifest at `spec/setup_acceptance_node.pp`.
The framework applies it automatically on each node before your tests run.

For logic that needs to branch on facts, pass a block to `configure_beaker`:

```ruby
configure_beaker do |host|
  if fact_on(host, 'os.name') == 'CentOS'
    install_package(host, 'epel-release')
  end
end
```

By default the framework installs your module and its dependencies by resolving `metadata.json`.
If you'd rather supply them yourself, `configure_beaker(modules: :fixtures)` uses the [fixtures](unit_testing.html) already checked out under `spec/fixtures/modules`, and `configure_beaker(modules: nil)` hands you full control.

{% include alert.html type="tip" content="Acceptance tests are slow and resource-hungry compared to unit tests, so keep them for behavior you genuinely can't verify in a unit test. Reach for them when an OS difference, a real service, or an end-to-end interaction is the thing under test." %}
