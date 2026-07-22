---
layout: default
title: "Enforcing Consistent Style"
---

Linting is a form of static code analysis that focuses on catching style and formatting inconsistencies.
In the Puppet world, this generally means ensuring that manifests are written to the [Puppet Language Style Guide](https://help.puppet.com/core//current/Content/PuppetCore/style_guide.htm),
but other more specific checks have been added over the years.
For example, recently [a check was added](https://github.com/voxpupuli/puppet-lint-exec_idempotency-check) to warn if an `exec` resource was written in a way that would never be idempotent.

It's worth knowing that while linters often indicate problems in the code, they're not always guaranteed to catch all syntax errors.
Make sure to read about the `puppet_syntax` task.
{: .tip }

The linters included in the Vox Pupuli test suite will validate Puppet manifests, `.erb` and `.epp` template files, module metadata, and Ruby code.
Some checks can automatically fix the offending bit of code.

## Linting Puppet code

Make sure that you have [set up the `voxpupuli-test` suite](setup.html#setting-up-the-vox-pupuli-test-suite).
Use `bundle exec rake -T` to get a list of tasks available.
The `lint` and `lint_fix` task will check Puppet manifests.

```console
$ bundle exec rake lint
manifests/init.pp:7:unquoted_resource_title:WARNING:unquoted resource title
manifests/init.pp:4:trailing_whitespace:ERROR:trailing whitespace found
manifests/init.pp:4:manifest_whitespace_class_name_single_space_after:ERROR:there should be a single space between the class or resource name and the next item
manifests/init.pp:10:manifest_whitespace_double_newline_end_of_file:ERROR:there should be a single newline at the end of a manifest
```

Try running the `lint_fix` task instead and you'll see most or all of the offenses marked as `FIXED` instead of `ERROR` or `WARNING` indicating that it has fixed the source files for you.
Some offenses cannot be fixed automatically and you may have to update them yourself.

If you use Jig, `jig validate` runs the `validate` and `lint` tasks together (equivalent to `bundle exec rake validate lint`).
It doesn't run `lint_fix`, so run the `lint_fix` task directly when you want automatic fixes.

### Configuring the Puppet linter

You can disable any of the checks you like by creating a `.puppet-lint.rc` file in the root of your module.
For example, if I have a really big monitor and want to use its full width, I can disable those checks with

```text
--no-140chars-check
--no-80chars-check
```

You can add any other configuration flags you like in this file.
Run `bundle exec puppet-lint --help` to see a list of options and all the checks it is running.

You can also add [control comments](http://puppet-lint.com/controlcomments/) to ignore a check for specific parts of the manifest.


## Linting module metadata

The suite can ensure that your `metadata.json` meets specifications with the `metadata_lint` task.
If there are syntax errors, those will need to be fixed before it will lint properly.

```console
$ bundle exec rake metadata_lint
(ERROR) required_fields: The file did not contain a required property of 'author'
Errors found in metadata.json
```

## Linting Ruby code

If you have any Ruby code in your module, such as facts, functions, types, etc. then you can check it with the `rubocop` tasks.
The `rubocop:autocorrect` task will fix only the offenses which are known to work reliably and the `rubocop:autocorrect_all` task will also fix those which don't always transform properly.
Make sure to run unit tests after using these autocorrect tasks.

```console
$ bundle exec rake rubocop
Running RuboCop...

# .....

Offenses:

spec/spec_helper.rb:1:1: C: [Correctable] Style/FrozenStringLiteralComment: Missing frozen string literal comment.
require 'voxpupuli/test/spec_helper'
^
spec/spec_helper.rb:2:1: C: [Correctable] Layout/TrailingEmptyLines: 1 trailing blank lines detected. (https://rubystyle.guide#newline-eof)
spec/unit/facter/foo_spec.rb:7:10: C: RSpec/DescribeSymbol: Avoid describing symbols. (https://www.rubydoc.info/gems/rubocop-rspec/RuboCop/Cop/RSpec/DescribeSymbol)
describe :foo, type: :fact do
         ^^^^^^
spec/unit/facter/foo_spec.rb:38:3: C: [Correctable] RSpec/HookArgument: Omit the default :each argument for RSpec hooks. (https://rspec.rubystyle.guide/#redundant-beforeeach, https://www.rubydoc.info/gems/rubocop-rspec/RuboCop/Cop/RSpec/HookArgument)
  before :each do
  ^^^^^^^^^^^^

7 files inspected, 4 offenses detected, 3 offenses autocorrectable
Finished in 0.25022 seconds
RuboCop failed!
```

Note that some of the offenses are autocorrectable and some are not.
Many offenses will include the style guide URL explaining what syntax is preferred and if there are configurable options for the check (called a cop in Rubocop lingo.)

### Configuring Rubocop

Rubocop and its cops can be configured in the `.rubocop.yml` file in the root of your module.
The following configuration disables some of the warnings from the above run and enables wider lines of text.

```yaml
Style/FrozenStringLiteralComment:
  Enabled: false
Layout/TrailingEmptyLines:
  Enabled: false
Layout/LineLength:
  Max: 180
```

You can also use source code directives (which are very similar to the control comments for Puppet Lint.)

Cops can be disabled for blocks of code with:

```ruby
# rubocop:disable Layout/LineLength
[...very long lines of text...]
# rubocop:enable Layout/LineLength
```

Or they can be disabled for a single line by adding the comment at the end.

```ruby
for x in (0..19) # rubocop:disable Style/For
```

## Syntax checking files

The test suite has the ability to run syntax checks on Puppet manifests, Ruby code, Hiera config files, templates, etc.
You'll see several `syntax` and `validate` tasks in the output of `bundle exec rake -T`.
We'll focus on `validate` specifically since it invokes the other tasks for you.

```console
$ bundle exec rake validate
ruby -c lib/facter/foo.rb
Syntax OK
---> syntax:manifests
Could not parse for environment *root*: Syntax error at 'foo' (file: /Users/ben.ford/Projects/demo/manifests/init.pp, line: 4, column: 13)
```

After fixing the error on `line: 4, column: 13`, the task finishes running and the output looks like

```console
$ bundle exec rake validate
ruby -c lib/facter/foo.rb
Syntax OK
---> syntax:manifests
---> syntax:templates
---> syntax:hiera:yaml
```
