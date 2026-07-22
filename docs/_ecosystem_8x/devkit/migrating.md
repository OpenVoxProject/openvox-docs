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
| `pdk convert`       | _not needed_     |                                  |
| `pdk update`        | `jig update`*    | `bundle exec msync update`*      |
| `pdk validate`      | `jig validate`   | `bundle exec rake validate lint` |
| `pdk test unit`     | `jig test unit`  | `bundle exec rake spec`          |

{% include alert.html type="note" title="*NOTE" content="`pdk update` operates in context of a single module. In contrast, the replacement ModuleSync commands (`jig update` and `bundle exec msync update`) should be run in the template repository to push updates to all your modules at once. [Read more](modulesync.html)." %}

Browse through the individual subpages of this Developer Tooling section to learn more about each component.
