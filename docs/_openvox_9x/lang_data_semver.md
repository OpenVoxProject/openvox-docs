---
layout: default
title: "Language: Data types: SemVer and SemVerRange"
---

[data type]: lang_data_type.html
[abstract types]: lang_data_abstract.html

OpenVox has two related data types for semantic versions. A `SemVer` value is a single version, such as the
version of a module. A `SemVerRange` value is a set of versions, such as the versions a dependency will
accept. The `SemVer` data type can also be parameterized with one or more ranges, which is how you check that
a version falls within what you allow.

Semantic versions follow [semver.org](https://semver.org): a `major.minor.patch` number, with an optional
`-prerelease` and `+build` on the end.

## SemVer

### Creating a SemVer

Parse a version from a string, or build one from its parts. The parts are `major`, `minor`, `patch`, and
optionally a prerelease and a build:

```puppet
notice(SemVer('1.2.3'))          # 1.2.3
notice(SemVer(1, 2, 3, 'rc1'))   # 1.2.3-rc1
```

You can also pass a hash, which is useful when you assemble the version from data:

```puppet
notice(SemVer({'major' => 2, 'minor' => 0, 'patch' => 0})) # 2.0.0
```

A build identifier follows a `+`, and a prerelease follows a `-`:

```puppet
notice(SemVer('2.0.0-beta.1+build.5')) # 2.0.0-beta.1+build.5
```

### Comparing versions

Versions compare by precedence, not as strings, so each part is compared as a number and `1.10.0` is newer
than `1.2.0`. A prerelease is older than the release it leads up to.

```puppet
notice(SemVer('1.10.0') > SemVer('1.2.0'))    # true
notice(SemVer('1.0.0-rc1') < SemVer('1.0.0')) # true
notice(SemVer('1.2.3') == SemVer('1.2.3'))    # true
```

The `<`, `>`, `<=`, `>=`, `==`, and `!=` operators all work, which lets you sort versions or pick the newest.

### Reading the parts of a version

A version is a single opaque value. You can build one from its parts, but you cannot read them back out:
there are no members to call, and the type does not support indexing.

```puppet
$ver = SemVer('1.2.3')

$ver.major
# Error: Unknown function: 'major'.

$ver['major']
# Error: Operator '[]' is not applicable to a Semver.
```

Usually you don't need the parts. Comparing whole versions, or matching against a range, answers the
question directly and handles precedence for you. If you genuinely need one part, convert the version to a
string and parse it, keeping in mind that a prerelease or build identifier makes that messier:

```puppet
$ver = SemVer('1.2.3')

notice(split(String($ver), '[.]')[0]) # 1
```

## Matching a version against a range

The most common thing you do with versions is check whether one falls within an allowed range. Parameterize
the `SemVer` data type with one or more ranges and match against it:

```puppet
notice(SemVer('1.5.0') =~ SemVer['>=1.0.0 <2.0.0']) # true
notice(SemVer('2.5.0') =~ SemVer['>=1.0.0 <2.0.0']) # false
```

Listing several ranges matches a version in any of them, which is how you express an "or":

```puppet
$type = SemVer['>=1.0.0 <2.0.0', '>=3.0.0 <4.0.0']

notice(SemVer('3.1.0') =~ $type) # true
notice(SemVer('2.5.0') =~ $type) # false
```

A range string uses the [npm range grammar](https://github.com/npm/node-semver#range-grammar). Alongside the
plain comparators, the common shorthands are:

| Range      | Matches |
| ---------- | ------- |
| `~1.5.0`   | `>=1.5.0` and `<1.6.0`, allowing patch updates. |
| `^1.0.0`   | `>=1.0.0` and `<2.0.0`, allowing minor and patch updates. |
| `1.5.x`    | Any `1.5` version. |
| `1.0.0 - 2.0.0` | A range with both ends included. |

A plain range does not match prereleases, so `2.0.0-rc1` fails `>=1.0.0 <3.0.0` even though the release
`2.0.0` would match. This keeps a released constraint from accepting a prerelease by accident.
{: .tip }

## SemVerRange

A `SemVerRange` value holds a range on its own, rather than as a parameter of the `SemVer` type. It is what a
module's dependency constraint parses to, and you can build one directly.

### Creating a SemVerRange

Parse a range from a string with the same grammar used above:

```puppet
notice(SemVerRange('>=1.0.0 <2.0.0')) # >=1.0.0 <2.0.0
```

You can also build one from a lower and upper version, where the upper bound is included unless you pass
`true` to exclude it, or from a hash with `min`, `max`, and `exclude_max` keys:

```puppet
$range = SemVerRange(SemVer('1.0.0'), SemVer('2.0.0'))

notice(SemVer('1.5.0') =~ SemVer[$range]) # true
notice(SemVer('2.0.0') =~ SemVer[$range]) # true, max included
```

The upper bound is included by default. Pass `true` as a third argument to leave it out, or use the hash
form, which takes `min`, `max`, and `exclude_max` keys. These two ranges are the same:

```puppet
$excl = SemVerRange(SemVer('1.0.0'), SemVer('2.0.0'), true)

$excl_hash = SemVerRange({
  'min'         => SemVer('1.0.0'),
  'max'         => SemVer('2.0.0'),
  'exclude_max' => true,
})

notice(SemVer('1.9.9') =~ SemVer[$excl])      # true
notice(SemVer('2.0.0') =~ SemVer[$excl])      # false
notice(SemVer('2.0.0') =~ SemVer[$excl_hash]) # false
```

A range built from a minimum and maximum matches correctly, but its string form is unreliable: printing one
shows the two bounds reversed. Ranges parsed from a string print as written. Match with a range rather than
displaying it.

```puppet
notice($range) # 2.0.0 - 1.0.0
```

Pass a `SemVerRange` value to the `SemVer` type, as above, to match versions against it. A single range
cannot use the `||` "or" operator; to allow disjoint ranges, give the `SemVer` type several range parameters
instead, as in the matching example earlier.

## The `SemVer` and `SemVerRange` data types

The [data type][data type] of a version is `SemVer`, and the [data type][data type] of a range is
`SemVerRange`.

### Parameters

`SemVer` takes any number of ranges as parameters, each a range string or a `SemVerRange` value, and matches
a version that falls in any of them. With no parameters it matches any version. `SemVerRange` takes no
parameters; it matches any range value.

```puppet
notice(SemVer('1.2.3') =~ SemVer) # true, any version
notice(SemVerRange('>=1.0.0') =~ SemVerRange) # true, any range
```

### Examples

- `SemVer` --- matches any version.
- `SemVer['>=1.0.0 <2.0.0']` --- matches a version in that range.
- `SemVer['>=1.0.0 <2.0.0', '>=3.0.0']` --- matches a version in either range.
- `SemVerRange` --- matches any range value.

### Related data types

`SemVer` and `SemVerRange` are both `Scalar` and part of `RichData`, but they are not `ScalarData` and not
`Data`:

```puppet
$v = SemVer('1.2.3')

notice($v =~ Scalar)     # true
notice($v =~ RichData)   # true
notice($v =~ ScalarData) # false
notice($v =~ Data)       # false
```

The `Data` type covers only the JSON-compatible types, so a parameter or function that expects `Data` does
not accept a `SemVer` or `SemVerRange`. Use `RichData`, or the specific type, when you need to accept one.

You can also use [abstract types][abstract types] to match a value that might be a version. For example,
`Optional[SemVer]` matches a `SemVer` or `undef`.
