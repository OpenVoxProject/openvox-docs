---
layout: default
title: "Unit Testing with RSpec and RSpec Puppet"
---

Unit testing is the practice of breaking our project down into standalone chunks and testing each of them in a reasonable degree of isolation.
To (ab)use a common metaphor in the tech world, if our product is a car then the units might be wheels, headlights, and so on.
But that brings up another question: each of those "units" is itself made up of individual parts too; how far down the rabbithole do we go when defining what a unit means?

The answer to that is context dependent.
In the car metaphor, if we are an auto _assembler_ then we'll make sure that the engine runs properly before we install it.
But if we are the _manufacturer_ of that engine, then we will test the dickens out of each part before the engine is even built.

In general, when we write unit tests we focus on the things that we create and leave the testing of upstream modules to their own authors.

## Unit testing Puppet code

In the Puppet ecosystem, the typical unit is a _class_ or a _defined type_ so we write one or more `spec tests` for each.

RSpec Puppet will build a mini-environment for our module with any runtime dependencies or other things it requires.
These are called _fixtures_.
Then it will compile a tiny catalog for each test and all we have to do is inspect that catalog to validate whether it has the resources and parameters that we expect.

For example, a (very abbreviated) `puppet-nginx` spec test might look like this:

```ruby
require 'spec_helper'

describe 'nginx' do
  on_supported_os.each do |os, facts|
    context "on #{os} with OpenFact #{facts[:facterversion]} and OpenVox #{facts[:puppetversion]}" do
      let(:facts) do
        facts
      end

      describe 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('nginx') }
        it { is_expected.to contain_class('nginx::package') }
        it { is_expected.to contain_class('nginx::config').that_requires('Class[nginx::package]') }
        it { is_expected.to contain_class('nginx::service').that_subscribes_to('Class[nginx::package]') }
        it { is_expected.to contain_class('nginx::service').that_subscribes_to('Class[nginx::config]') }
      end

    end
  end
end
```

This uses [`facterdb`](https://github.com/voxpupuli/facterdb) and [`rspec-puppet-facts`](https://github.com/voxpupuli/rspec-puppet-facts) to run your the test on all supported platforms from the module's `metadata.json`.

To run your unit tests, use `jig test unit`, which wraps `bundle exec rake spec`.
Either form needs the module's gems installed, so run `bundle install` first.

If you'd like to constrain a test run to only a specific OS or OS release, you can do so with environment variables:

```console
export SPEC_FACTS_OS=centos
export SPEC_FACTS_OS=centos-7
```

The test just validates that the catalog compiles and contains the `nginx`, `nginx::package`, `nginx::config`, and `nginx::service` classes with specified relationships on each tested platform.

The [`rspec-puppet` tutorial](https://rspec-puppet.com/tutorial/) will walk you through learning how to test various conditions and the matchers you can use.
You'll start simple and iteratively build in complexity.
Just remember that the module scaffolding already set up the framework -- you don't need to run `rspec-puppet-init` yourself.


## Unit testing Ruby code

RSpec Puppet is an extension to the RSpec testing framework.
When testing Ruby code, you'll use RSpec directly and the units are _classes_ or _modules_ or such.
Writing the actual tests is out of scope of this guide, but you'll find it very similar to the `rspec-puppet` you already know.

You'll find guides to follow on the [RSpec homepage](https://rspec.info), just remember that you don't have to set up the framework with the `rspec --init` command -- it's already done for you!


{% include alert.html type="tip" content="The test suite includes a task that will run the linter, syntax checker, and unit tests all at once: `bundle exec rake test`." %}
