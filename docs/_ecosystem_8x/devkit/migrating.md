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

{% include alert.html type="tip" content="There are a few exceptions to this pattern. For example, Jig is an installed package and VoxBox is a Docker container." %}

| You used to type... | Now you type...                  |
|---------------------|----------------------------------|
| `pdk new module`    | `jig new module`                 |
| `pdk new class`     | `jig new class`                  |
| `pdk build`         | `jig new module`                 |
| `pdk release`       | `jig release`                    |
| `pdk convert`       | _not needed_                     |
| `pdk update`        | `bundle exec msync update`       |
| `pdk validate`      | `bundle exec rake validate lint` |
| `pdk test unit`     | `bundle exec rake spec`          |

Browse through the individual subpages of this Developer Tooling section to learn more about each component.
