---
layout: default
title: "Setting up the Vox Pupuli DevKit"
---

Most of the Vox Pupuli developer kit is implemented in the Ruby language.
This means that most of setting up the devkit entails making sure that you have a working Ruby installation.
More advanced module maintainers might also configure Ruby version management so that you can test your modules under multiple Ruby and OpenVox versions.

The full instructions for installing Ruby and Bundler are out of scope for this guide,
but in general whether running RedHat family Linux, Debian family Linux, Windows, or macOS,
you will install packages such as `ruby`, `ruby-devel`, and `rubygems-bundler` using your system package management tooling.
The package names may vary slightly, and may also pull in dependencies like `gcc`.

If you're installing a custom version of Ruby or are on a platform like macOS which doesn't have a separate package for Bundler then you can install it directly with

``` console
sudo gem install bundler
```

Once you have a working Ruby environment you're ready to start using the Vox Pupuli testing suite!

If you'd prefer to run the testing tools via a container runtime like Docker or Podman,
then check out [Using VoxBox in CI](voxbox.html).
{: .tip }


## Installing a devkit component

Setup instructions for each component will tell you to add a line to your `Gemfile`.
This is a file that sits in the root of your project, in this case a Puppet module, and describes the Ruby packages (gems) that will be used.

Experiment with that now by creating a `fakemodule` directory to represent a module and adding a `Gemfile` to it.

```ruby
# fakemodule/Gemfile

gem 'openvox'
```

Now you can run OpenVox in context of that (fake) module's directory; navigate there and try it out.

```console
cd fakemodule
bundle install
bundle exec puppet --version
bundle exec puppet --help
```

You can specify the version you'd like to install by adding a second parameter in your `Gemfile`.

```ruby
# fakemodule/Gemfile

gem 'openvox', '~> 8.0'
```

Nearly all the tools in the Vox Pupuli test suite will be run via this pattern, so get used to typing `bundle exec`.


## Automating tasks

Most of the module test functionality is exposed via Rake tasks.
Let's try running some testing tasks from within a published Vox Pupuli module.

```console
git clone https://github.com/voxpupuli/puppet-nginx.git
cd puppet-nginx
bundle install
bundle exec rake -T             # shows all available tasks
bundle exec rake validate       # runs a specific task
```

These tasks are part of the `voxpupuli-test` framework.
To understand how they work, let's start smaller and add a simple `hello` task to the `fakemodule` directory.

```ruby
# fakemodule/Rakefile

desc "Hello world!"
task :hello do
  puts "Hello World!"
end
```

and then run it with

```console
bundle exec rake hello
bundle exec rake -T
```

Each task listed with `rake -T` is similarly a bit of Ruby code automating each function.
The ones in the `voxpupuli-test` suite are installed via a Ruby gem managed with the `Gemfile` and imported into the `Rakefile`.

You'll find that almost all the test components work in similar ways.

## Setting up the Vox Pupuli Test suite

The [`voxpupuli-test`](https://github.com/voxpupuli/voxpupuli-test) suite is the standardized metapackage for the devkit.
Adding it to your module will pull in most other testing gems and give you the framework we'll be discussing in the rest of the Dev Tooling guide.
You will need to add it to four files (two of which we just went over) and two that you might need to create.

Add the gem to your `Gemfile` and run `bundle install`:

```ruby
gem 'voxpupuli-test'
```

Then, at the top of your `Rakefile`, add:

```ruby
require 'voxpupuli/test/rake'
```

Add this to the top of your `spec/spec_helper.rb`, creating it if needed.

```ruby
require 'voxpupuli/test/spec_helper'
```

Add this to your `.rubocop.yml`, creating it if needed.

```yaml
inherit_gem:
  voxpupuli-test: rubocop.yml
```

Now see all the tooling you have available to you:

```console
$ bundle exec rake -T
rake check                                                                      # Run static pre release checks
rake check:dot_underscore                                                       # Fails if any ._ files are present in directory
rake check:git_ignore                                                           # Fails if directories contain the files specified in .gitignore
rake check:misplaced_files                                                      # Check that no misplaced files exist in module code/data
rake check:test_file                                                            # Fails if .pp files present in tests folder
rake check:trailing_whitespace                                                  # Check for trailing whitespace
rake check:utf8                                                                 # Check that all module code and data are valid UTF-8 without BOM
rake fixtures:clean                                                             # Clean up the fixtures directory
rake fixtures:prep                                                              # Create the fixtures directory
rake lint                                                                       # Run puppet-lint
rake lint_fix                                                                   # Run puppet-lint
rake metadata_lint                                                              # Run metadata-json-lint
rake parallel_spec                                                              # Run spec tests in parallel and clean the fixtures directory if successful
rake parallel_spec:standalone                                                   # Parallel spec tests
rake rubocop                                                                    # Run RuboCop
rake rubocop:autocorrect                                                        # Autocorrect RuboCop offenses (only when it's safe)
rake rubocop:autocorrect_all                                                    # Autocorrect RuboCop offenses (safe and unsafe)
rake spec                                                                       # Run spec tests and clean the fixtures directory if successful
rake spec:standalone                                                            # Run RSpec code examples
rake strings:generate[patterns,debug,backtrace,markup,json,markdown,yard_args]  # Generate Puppet documentation with YARD
rake strings:generate:reference[patterns,debug,backtrace]                       # Generate Puppet Reference documentation
rake strings:gh_pages:update                                                    # Update docs on the gh-pages branch and push to GitHub
rake strings:validate:reference[patterns,debug,backtrace]                       # Validate the reference is up to date
rake syntax                                                                     # Syntax check for Puppet manifests, templates and Hiera
rake syntax:hiera                                                               # Syntax check Hiera config files
rake syntax:manifests                                                           # Syntax check Puppet manifests
rake syntax:templates                                                           # Syntax check Puppet templates
rake test                                                                       # Runs all necessary checks on a module
rake validate                                                                   # Check syntax of Ruby files and call :syntax and :metadata_lint
rake validate:ruby                                                              # Validate all .rb files
rake validate:strings                                                           # validate REFERENCE.md if it exists
```

## 🗂️ [advanced] Running multiple Ruby versions

It is beyond the scope to describe how to set up and maintain multiple Ruby versions.
It's often simpler to set your local Ruby environment to match the production environment in your infrastructure and then to rely on your CI pipeline to validate a matrix of OpenVox and Ruby versions.
Nevertheless, the ability to do local direct testing with a variety of versions can be very useful, especially if you're maintaining a public module or pre-flighting an OpenVox upgrade before rolling updates out.

If you'd like to explore the possibility, here is a non-exhaustive list of some Ruby version managers to try out.

* [Mise](https://mise.jdx.dev) and [asdf](https://github.com/asdf-vm/asdf)
  * Both pluggable runtime version managers that let you change between Node.js versions the same as you would with Ruby.
  Being so featureful can make them a bit slower than the more minimal options, but the familiarity of managing all your runtimes the same way often makes up for it.
* [rbenv](https://rbenv.org)
  * A minimal Ruby version manager that lets you configure the desired version on a per-project basis, changing versions as you enter the directory on the command line.
* [rvm](https://rvm.io)
  * The original Ruby version manager. It will install and manage Ruby versions and multiple gemsets for you.
  It's fallen somewhat out of fashion these days because the way that it hooks into the shell environment can be fragile.
* [rv](https://github.com/spinel-coop/rv)
  * A brand new very fast Ruby gem and project manager. Some of us have tried the tool and love its potential. However, you should be aware that it's very new and hasn't been as battle tested as other options.


## 🧩 [advanced] Overriding dependencies

This section describes an ecosystem mitigation that is sometimes required, but never recommended if you can avoid it.
{: .warning }

The Rubygems environment will manage dependencies for you and recursively install all the gems needed by the gems you specify.
This is very convenient, but it does rely on _all module and gem authors_ to have properly maintained their dependencies.
If you are testing third-party modules, you may stumble into modules in which these dependencies have not yet been updated to
specify OpenVox instead of Puppet and run into compatibility issues or actually be testing something you didn't intend to.

If you have the ability to fix the module/gem, then do that and help get the fix published so the whole ecosystem improves.
But if you can't or don't have the time, then you can temporarily _alias_ one gem name to another.

```console
bundle plugin install 'bundler-alias'
bundle config set aliases 'puppet:openvox'
```

Then `bundle install` and run your tests as usual.
Any gem that requires `puppet` will be transparently rewritten to depend on `openvox` instead.
Now your tests will actually test what you expect them to be testing.
