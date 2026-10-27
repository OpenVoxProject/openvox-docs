---
layout: default
title: "Custom facts walkthrough"
---

[Plugins in Modules]: /openvox/latest/plugins_in_modules.html
[Adding plug-ins to a module]: /openvox/latest/plugins_in_modules.html
[Facts overview]: fact_overview.html
[openvoxdb]: /openvoxdb/latest
[Fiddle]: https://github.com/ruby/fiddle

You can add custom facts by adding snippets of Ruby code to the OpenVox server. OpenVox then uses [Plugins in Modules][] to distribute the facts to all agents.

For information on how to add custom facts to modules, see [Adding plug-ins to a module][].

## Adding custom facts to OpenFact

Sometimes you need to be able to write conditional expressions based on site-specific data that just isn't available via OpenFact, or perhaps you'd like to include it in a template.

Because you can't include arbitrary Ruby code in your manifests, the best solution is to add a new fact to OpenFact.
These additional facts can then be distributed to OpenVox agent and are available for use in manifests and templates, just like any other fact is.

> **Note:** OpenFact provides a [custom facts API](https://github.com/OpenVoxProject/openfact/blob/main/Extensibility.md#custom-facts-compatibility).

## Loading custom facts

OpenFact offers multiple methods of loading facts:

- `$LOAD_PATH`, or the Ruby library load path
- The `--custom-dir` command line option
- The environment variable 'FACTERLIB'

You can use these methods to do things like test files locally before distributing them, or you can arrange to have a specific set of facts available on certain machines.

The `facter` command does not load the custom facts that the agent downloads from your modules
unless you pass `-p`. Without it, those facts are missing from the output.

### Using the Ruby load path

OpenFact searches all directories in the Ruby `$LOAD_PATH` variable for
subdirectories named `facter`, and loads all Ruby files in those directories.
If you had a directory in your `$LOAD_PATH` like `~/lib/ruby`, set up like
this:

```text
    #~/lib/ruby
    └── facter
        ├── system_load.rb
        └── users.rb
```

OpenFact loads `facter/system_load.rb` and `facter/users.rb`.

### Using the `--custom-dir` command line option

OpenFact can take multiple `--custom-dir` options on the command line, each naming a directory
to search for custom facts. OpenFact attempts to load all Ruby files in the specified directories.
This allows you to do something like this:

```text
    #~/my_facts
    └── system_load.rb
    #~/my_other_facts
    └── users.rb

    $ facter --custom-dir=./my_facts --custom-dir=./my_other_facts system_load users
    system_load => 0.25
    users => thomas,pat
```

### Using the `FACTERLIB` environment variable

OpenFact also checks the environment variable `FACTERLIB` for a delimited (semicolon for Windows and colon for all
other platforms) set of directories, and tries to load all Ruby files in those directories.
This allows you to do something like this:

```text
    #~/my_facts
    └── system_load.rb
    #~/my_other_facts
    └── users.rb

    $ export FACTERLIB="./my_facts:./my_other_facts"
    $ facter system_load users
    system_load => 0.25
    users => thomas,pat
```

## Two parts of every custom fact

Most facts have at least two elements:

1. A call to `Facter.add('fact_name')`, which determines the name of the fact.
2. A `setcode` statement for simple resolutions, which is evaluated to determine the fact's value.

Facts *can* get a lot more complicated than that, but those two together are the most common implementation of a custom fact.

## Executing shell commands in custom facts

OpenVox gets information about a system from OpenFact, and the most simple way for OpenFact to
get that information is by executing shell commands. You can then parse and manipulate the
output from those commands using standard Ruby code.

> **Note:** However, it is important to also check if any of the OpenVox agent bundled Ruby Libraries can be used.

The OpenFact API gives you a few ways to
execute shell commands:

- To run a command and use the output verbatim, as your fact's value, you can pass the command into `setcode` directly. For example: `setcode 'uname --hardware-platform'`
- If your fact is more complicated than that, you can call `Facter::Core::Execution.execute('uname --hardware-platform')` from within the `setcode do`...`end` block.
  Whatever the `setcode` statement returns is used as the fact's value.
- Your shell command is also a Ruby string, so you need to escape special characters if you want to pass them through.

> **Note:** Not everything that works in a terminal works in a fact. Pipes (`|`) and similar
> operators work, but a command that starts with shell syntax such as `if` fails with "command not
> found", because OpenFact runs the first word as the command. Write the logic in Ruby, or pass it to
> a shell explicitly, for example `sh -c 'if true; then echo yes; fi'`.

### Example

To get the output of `uname --hardware-platform` to single out a specific type of workstation, you create a new custom fact.

1. Start by giving the fact a name, in this case, `hardware_platform`.

2. Create your new fact in a file, `hardware_platform.rb` on an OpenVox agent system:

    ```ruby
    #~/my_facts/hardware_platform.rb

    Facter.add('hardware_platform') do
      setcode do
        Facter::Core::Execution.execute('/bin/uname --hardware-platform')
      end
    end
    ```

3. Use the instructions in the [Plugins in Modules][] page to copy the new fact to a module and distribute it. During your next OpenVox run, the value of the new fact is available to use in your manifests and templates.

## Accessing other facts

You can write a custom fact that uses other facts by calling `Facter.value`. For part of a
structured fact, either index into the hash, `Facter.value(:os)['family']`, or use a dotted name,
`Facter.value('os.family')`. If the fact fails to resolve or is not present, OpenFact returns
`nil`. Make sure facts do not depend on each other in a loop.

For example, this fact combines the operating system name and major release into one string, such
as `Debian 12`:

```ruby
Facter.add(:os_label) do
  setcode do
    "#{Facter.value('os.name')} #{Facter.value('os.release.major')}"
  end
end
```

## Configuring custom facts

Facts have a few properties that you can use to customize how they are evaluated.

### Confining custom facts

One of the more commonly used properties is the `confine` statement, which
restricts the fact to only run on systems that matches another given fact.
However, this should be done cautiously to avoid introducing cyclic dependencies between facts.

An example of the confine statement would be something like the following:

```ruby
Facter.add(:powerstates) do
  confine :kernel => 'Linux'
  setcode do
    # Put your fact code here.
    Facter::Core::Execution.execute('cat /sys/power/states')
  end
end
```

Only the code inside the `setcode` block is confined. Code outside it, directly in the
`Facter.add` block, runs when OpenFact loads the file, on every node.

This fact uses sysfs on Linux to get a list of the power states that are
available on the given system. Since this is only available on Linux systems,
we use the `confine` statement to ensure that this fact isn't needlessly run on
systems that don't support this type of enumeration.

To confine on part of a structured fact, use a dotted name, for example
`confine 'os.family' => 'RedHat'`.

In our next example the application has different config paths for different OS:

- RedHat: `/etc/sysconfig/application`
- Debian: `/etc/default/application`

Example with access to another fact:

```ruby
Facter.add(:application_version) do
  confine do
    app_cfg_file = case Facter.value('os')['family']
                   when 'RedHat'
                     '/etc/sysconfig/application'
                   when 'Debian'
                     '/etc/default/application'
                   else
                     'notexisting'
                   end

    File.exist?(app_cfg_file)
  end

  setcode do
    Facter::Core::Execution.execute('/opt/app/bin/app config')
  end
end
```

The example retrieves the os fact and uses the family key to compare the OS, then applies logic to determine which application config path to check for.

> **Note:** More information on other ways to confine can be found in the [Facts overview].

### Custom facts precedence

A single fact can have multiple **resolutions**, each of which is a different way
of ascertaining what the value of the fact should be. It's very common to have
different resolutions for different operating systems, for example. It's easy to
confuse facts and resolutions because they are superficially identical --- to add
a new resolution to a fact, you simply add the fact again, only with a different
`setcode` statement.

When a fact has more than one resolution, the first resolution that returns a value other
than `nil` sets the fact's value. The way that OpenFact decides the issue of resolution precedence is the
weight property. Once OpenFact rules out any resolutions that are excluded because of `confine` statements,
the resolution with the highest weight is evaluated first. If that resolution returns `nil`,
OpenFact moves on to the next resolution (by descending weight) until it gets a value for the fact.

By default, the weight of a fact is the number of confines for that resolution, so
that more specific resolutions take priority over less specific resolutions.

```ruby
# Check to see if this server has been marked as a postgres server
Facter.add(:role) do
  has_weight 100
  setcode do
    if File.exist? '/etc/postgres_server'
      'postgres_server'
    end
  end
end

# Guess if this is a server by the presence of the pg_create binary
Facter.add(:role) do
  has_weight 50
  setcode do
    if File.exist? '/usr/sbin/pg_create'
      'postgres_server'
    end
  end
end

# If this server doesn't look like a server, it must be a desktop
Facter.add(:role) do
  setcode do
    'desktop'
  end
end
```

> **Note:** External facts have a weight of 10000. To override an external fact with a custom
> fact of the same name, give the custom fact a weight above 10000.

### Custom facts execution timeouts

You can limit how long a whole resolution runs, and how long each command in it runs.

To limit a whole resolution, pass `timeout` to `Facter.add`. If the resolution takes longer,
OpenFact logs an error and the fact has no value. OpenFact still waits for a command that the
resolution started, so give long-running commands their own, shorter timeout as well:

```ruby
Facter.add(:application_config, timeout: 10) do
  setcode do
    Facter::Core::Execution.execute('/opt/app/bin/app config', timeout: 5)
  end
end
```

To limit a single command, pass `timeout` to `Facter::Core::Execution.execute`. Without it, a
command can run for up to 300 seconds. When the command times out, or cannot be found,
`execute` raises `Facter::Core::Execution::ExecutionFailure`:

```ruby
Facter.add(:sleep) do
  setcode do
    begin
      Facter::Core::Execution.execute('sleep 10', timeout: 5)
      'did not time out'
    rescue Facter::Core::Execution::ExecutionFailure
      'timed out'
    end
  end
end
```

To get a value back instead of an exception when the command cannot be found, pass `on_fail`. For
example, `Facter::Core::Execution.execute('app config', on_fail: nil)` returns `nil` if `app` is
not installed. A command that runs but exits with a non-zero status does not count as a failure:
`execute` returns its output.

> **Note:** `Facter::Core::Execution.exec` has been deprecated in favor of `Facter::Core::Execution.execute`. This is important when migrating from older versions of Facter.

### Logging

It's often useful to include logging within custom facts to help with troubleshooting and development. You can log messages with OpenFact's logging methods:

```ruby
Facter.add(:application_version) do
  setcode do
    Facter.debug("Custom fact 'application_version' running")
    Facter::Core::Execution.execute('/opt/app/bin/app --version')
  end
end
```

The logging methods are `Facter.debug` and `Facter.warn`, their `Facter.debugonce` and
`Facter.warnonce` variants, which log a given message only once, and `Facter.log_exception` for
logging an exception. To see debug messages, run `facter --debug`.

## Structured custom facts

Structured facts take the form of either a hash or an array. To create a structured fact, return a hash or an array from the `setcode` statement.

You can see some relevant examples in the [writing structured facts](fact_overview.html#writing-structured-facts) section of the [Facts overview].

## Aggregate resolutions

If your fact combines the output of multiple commands, it may make sense to use aggregate resolutions. An aggregate resolution is split into "chunks", each one responsible for resolving one piece of the fact.
After all of the chunks have been resolved separately, they're combined into a single flat or structured fact and returned.

Aggregate resolutions have several key differences compared to simple resolutions, beginning with the fact declaration. To introduce an aggregate resolution, add the `:type => :aggregate` parameter:

```ruby
Facter.add(:fact_name, :type => :aggregate) do
    #chunks go here
    #aggregate block goes here
end
```

Each step in the resolution then gets its own named `chunk` statement:

```ruby
chunk(:one) do
    'Chunk one returns this. '
end

chunk(:two) do
    'Chunk two returns this.'
end
```

Aggregate resolutions *never* have a `setcode` statement. Instead, they have an optional `aggregate` block that combines the chunks.
Whatever value the `aggregate` block returns is the fact's value. Here's an example that just combines the strings from the two chunks above:

```ruby
aggregate do |chunks|
  result = ''

  chunks.each_value do |str|
    result += str
  end

  # Result: "Chunk one returns this. Chunk two returns this."
  result
end
```

If the `chunk` blocks all return arrays or hashes, you can omit the `aggregate` block. If you do, OpenFact automatically merges all of your data into one array or hash and uses that as the fact's value.

For more examples of aggregate resolutions, see the [aggregate resolutions](fact_overview.html#writing-facts-with-aggregate-resolutions) section of the [Facts overview] page.

## Windows Facts

Windows-based systems support custom facts just like Linux or other Unix-like systems.
The main difference is that many Windows-specific tasks, such as checking installed software or
reading from the registry, need platform-specific Ruby code or a PowerShell command run through
`Facter::Core::Execution.execute`.

Ruby's old `Win32API` library is deprecated. To call Windows APIs, use [Fiddle] or another Ruby
library.

## Viewing fact values

If your OpenVox servers are configured to use [OpenVoxDB][OpenVoxDB], you can view and search all of the facts for any node, including custom facts. See [the OpenVoxDB docs][openvoxdb] for more info.

## External facts

External facts let you set facts with an executable script or a structured data file instead of
Ruby code. See [External facts](external_facts.html).
