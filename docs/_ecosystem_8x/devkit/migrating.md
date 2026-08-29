---
layout: default
title: "Migrating Away from the PDK"
---

It's a little known secret in the Puppet ecosystem that most of the PDK's functionality was actually implemented by Vox Pupuli tooling under the hood.
This tooling was vendored in and managed by the PDK, so most users were only peripherally aware of it.
In other words, everything that was done with the PDK can also be done without it -- and more!

When migrating away from the PDK, the biggest change you'll notice that instead of the PDK being the single entrypoint for everything you'll be exposed to each tool on its own.
Most are shipped as gems that you'll add to a module's `Gemfile`.
This means that you'll maintain your own Ruby and Bundler installs, but most other tooling will be accessed via `bundle exec` commands in individual module repositories.

The `jig convert` command migrates a PDK-based module for you.
Run it from the module's root directory and it rewrites the module's `Gemfile`, `Rakefile`, and `spec/spec_helper.rb` to OpenVox- and VoxBox-compatible versions.
Nothing about it is specific to the PDK: it works on any module, so it's also the quickest way to bring a hand-maintained module onto the DevKit toolchain.
If the module has no `metadata.json`, or has one that's missing required keys, `jig convert` creates or repairs it first; see [the Jig page](jig.html#migrate-an-existing-module-to-jig) for the details.

```console
 ~/demo git:(main)  git status 
On branch main
nothing to commit, working tree clean

 ~/demo git:(main)  jig convert
convert successful: Gemfile, Rakefile, spec/spec_helper.rb

 ~/demo git:(main) ✗  git status
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
    modified:   Gemfile
    modified:   Rakefile
    modified:   spec/spec_helper.rb

no changes added to commit (use "git add" and/or "git commit -a")
 ~/demo git:(main) ✗
 ```

Before running commands in a new module repository, you'll need to run `bundle install`.
If you get an error about a command not being available, you probably just need to run `bundle install`.

There are a few exceptions to this pattern. For example, Jig is an installed package and VoxBox is a Docker container.
{: .tip }

Jig also contains thin wrappers around the `bundle exec` commands, so in many cases you can use the CLI patterns you're used to typing.
Because Jig does not attempt to hide the Bundler environment from you, it will still need the module's gems installed (`bundle install`) and ModuleSync configured properly.

{% include alert.html type="tip" title="Choosing command forms" content="If you want quick and familiar commands to run locally, then use the Jig wrapper commands. If you're running tests and such in CI or if you need to pass custom options then invoke the tools directly." %}

| You used to type... | Now you type...  | Or run tools directly...         |
|---------------------|------------------|----------------------------------|
| `pdk new module`    | `jig new module` |                                  |
| `pdk new class`     | `jig new class`  |                                  |
| `pdk build`         | `jig build`      |                                  |
| `pdk release`       | `jig release`    |                                  |
| `pdk convert`       | `jig convert`    |                                  |
| `pdk update`        | `jig msync update`* | `bundle exec msync update`*           |
| `pdk validate`      | `jig validate`   | `bundle exec rake validate lint rubocop` |
| `pdk test unit`     | `jig test unit`  | `bundle exec rake spec`          |

`jig validate` runs all three checks and stops at the first failure.
Pass `-s`, `-l`, or `-r` to run only the syntax, lint, or rubocop check; for example, `jig validate -sl` skips rubocop.

{% include alert.html type="note" title="*NOTE" content="`pdk update` operates in context of a single module. In contrast, the replacement ModuleSync commands (`jig msync update` and `bundle exec msync update`) should be run in the template repository to push updates to all your modules at once. [Read more](modulesync.html)." %}

If you used `jig update` with Jig 1.x, it was renamed to `jig msync update` in Jig 2.0 to make clear that it runs ModuleSync rather than anything Jig-native.
For Jig's own template-driven refresh of a single module, see [`jig renew`](jig.html#refreshing-a-module-from-its-templates).

Browse through the individual subpages of this Developer Tooling section to learn more about each component.
