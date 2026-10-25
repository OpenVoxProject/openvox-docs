---
layout: default
title: "External facts"
---

External facts let you use arbitrary executables or scripts as facts, or set facts statically with
structured data. If you want to write a fact in Perl, C, or a one-line text file, use an external
fact. To write facts in Ruby, see the [custom facts walkthrough](custom_facts.html).

## Where to put external facts

The best way to distribute external facts is with pluginsync. Put them in the `facts.d` directory
of a module, and the agent downloads them on its next run:

```text
<MODULEPATH>/<MODULE>/facts.d/
```

Without pluginsync, put external facts in one of the standard directories. OpenFact reads every
directory in the list that exists.

On Linux, Unix, and macOS, running as root:

```text
/opt/puppetlabs/facter/facts.d/
/etc/puppetlabs/facter/facts.d/
/etc/facter/facts.d/
/usr/local/etc/facter/facts.d/
```

On Windows, running as Administrator:

```text
C:\ProgramData\PuppetLabs\facter\facts.d\
```

Running as a non-root or non-Administrator user:

```text
<HOME DIRECTORY>/.facter/facts.d/
<HOME DIRECTORY>/.puppetlabs/opt/facter/facts.d/
```

When you run `facter` from the command line, you can use a different directory with the
`--external-dir` option.

> **Note:** These directories don't necessarily exist by default; you may need to create them. If
> you create the directory, make sure to restrict access so that only Administrators can write to
> the directory.

## Executable external facts

### Linux and Unix

An executable external fact is a script or program in an external facts directory. It must have
its execute bit set. Start a script with a shebang (`#!`) line that names its interpreter; a script
without one runs with `/bin/sh`.

An example external fact written in Python:

```python
#!/usr/bin/env python3
data = {"key1": "value1", "key2": "value2"}

for k in data:
    print(f"{k}={data[k]}")
```

Set the execute bit:

```console
chmod +x /etc/puppetlabs/facter/facts.d/my_fact_script.py
```

For OpenFact to parse the output, the script must print key/value pairs on standard output, one per
line:

```text
key1=value1
key2=value2
key3=value3
```

Using this format, a single script can return multiple facts.

A script can also print YAML or JSON, which OpenFact parses into structured facts:

```shell
#!/bin/sh
echo '{"datacenter": {"location": "fra1", "rack": "b12"}}'
```

This sets a `datacenter` fact with `location` and `rack` keys, so `facter datacenter.rack` prints
`b12`.

### Windows

Executable facts on Windows work by dropping an executable file into the external fact path.
Unlike on Unix, the file must end with one of these extensions:

- `.com` and `.exe`: binary executables
- `.bat` and `.cmd`: batch scripts
- `.ps1`: PowerShell scripts

Line endings can be either `LF` or `CRLF`. As on Unix, each script must print key/value pairs on
standard output, or YAML or JSON:

```text
key1=value1
key2=value2
key3=value3
```

#### Windows batch scripts

The file encoding for `.bat/.cmd` files must be `ANSI` or `UTF8 without BOM` (Byte Order Mark). With a BOM, `cmd.exe` cannot read the first line of the script, so a first line of `@echo off` fails and OpenFact logs a warning.

Here is a sample batch script which outputs facts using the required format:

```text
@echo off
echo key1=val1
echo key2=val2
echo key3=val3
REM Invalid - echo 'key4=val4'
REM Invalid - echo "key5=val5"
```

#### PowerShell scripts

PowerShell reads `.ps1` files saved as UTF-8, with or without a BOM, and as UTF-16.

Here is a sample PowerShell script which outputs facts using the required format:

```powershell
Write-Host "key1=val1"
Write-Host 'key2=val2'
Write-Host key3=val3
```

You should be able to save and execute this PowerShell script on the command line.

## Structured data external facts

OpenFact can parse structured data files stored in the external facts directory and set facts based on their contents.

Structured data files must use one of the supported data types and must have the correct file extension. OpenFact supports the following extensions and data types:

`.yaml`: YAML data, in the following format:

```yaml
---
key1: val1
key2: val2
key3: val3
```

`.json`: JSON data, in the following format:

```json
{
    "key1": "val1",
    "key2": "val2",
    "key3": "val3"
}
```

`.txt`: Key value pairs, of the `String` data type, in the following format:

```text
key1=value1
key2=value2
key3=value3
```

As with executable facts, structured data files can set multiple facts at once.

```json
{
  "datacenter":
  {
    "location": "bfs",
    "workload": "Web Development Pipeline",
    "contact": "Blackbird"
  },
  "provision":
  {
    "birth": "2017-01-01 14:23:34",
    "user": "alex"
  }
}
```

### Structured data external facts on Windows

All of the above types are supported on Windows with the following caveats:

- The line endings can be either `LF` or `CRLF`.
- The file encoding must be either `ANSI` or `UTF8 without BOM` (Byte Order Mark).

## Facts from environment variables

OpenFact also reads facts from environment variables named `FACTER_<name>`. This is useful for
testing, because the variable overrides a built-in fact of the same name:

```console
$ FACTER_kernel=windows facter kernel
windows
```

## Blocking and caching external facts

To block or cache an external fact in `facter.conf`, use the name of the file that sets it, such
as `datacenter.yaml`, not the fact name. See
[Configuring OpenFact with facter.conf](configuring_openfact.html#facts).

## Troubleshooting external facts

If an external fact does not appear in OpenFact's output, run `facter` with `--debug`. For facts
that the agent downloads from your modules, add `-p`. The debug output shows each command OpenFact
runs and each file it could not use.

For example, if a script prints a hyphen instead of an equals sign:

```shell
#!/bin/bash

echo "key1-value1"
```

the debug output shows that the script ran, but that OpenFact found nothing it could use in its
output:

```text
$ facter --debug key1
...
DEBUG Facter::Core::Execution::Posix - Executing command: /etc/puppetlabs/facter/facts.d/test.sh
DEBUG LegacyFacter::Util::DirectoryLoader - Structured data fact file /etc/puppetlabs/facter/facts.d/test.sh was parsed but was either empty or an invalid filetype (valid filetypes are .yaml, .json, and .txt).
...
```

## Drawbacks

While external facts provide a mostly-equal way to create variables for OpenVox, they have a few drawbacks:

- An external fact cannot internally reference another fact. However, due to parse order, you can reference an external fact from a Ruby fact.
- External executable facts are forked instead of executed within the same process.
