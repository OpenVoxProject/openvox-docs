---
layout: default
title: "Language: Data types: URI"
---

[abstract types]: lang_data_abstract.html
[data type]: lang_data_type.html
[enum]: lang_data_abstract.html#enum
[notundef]: lang_data_abstract.html#notundef
[new function]: function.html#new
[pattern]: lang_data_abstract.html#pattern
[strings]: lang_data_string.html

A `URI` value is a parsed uniform resource identifier. It differs from a string that happens to contain a
URL: a `URI` value knows its own parts, so you can read the scheme, host, or path individually instead of
picking them apart with a regular expression. When you use `URI` as a data type, you can also constrain
those parts.

A string is never automatically a URI. It becomes a `URI` value only when you construct one:

```puppet
notice('https://example.com' =~ URI) # false
notice(URI('https://example.com') =~ URI) # true
```

## Syntax

Construct a URI from a string with either the short form `URI(...)` or `URI.new(...)`. Both call the
[`new` function][new function]:

```puppet
$docs = URI('https://docs.openvoxproject.org/openvox/latest/')
$same = URI.new('https://docs.openvoxproject.org/openvox/latest/')
```

The string can be a full URI, a relative reference such as `/reports/latest`, or an opaque URI such as
`mailto:ops@example.com`.

### Creating a URI from its parts

You can also pass a hash of parts, which is useful when you assemble a URI from data:

```puppet
$endpoint = URI({
  scheme => 'https',
  host   => 'docs.example.com',
  path   => '/openvox',
})

notice($endpoint) # https://docs.example.com/openvox
```

Every key is optional. `port` takes a non-negative integer; the rest take non-empty strings. The scheme determines how
OpenVox assembles the result, so `scheme => 'https'` produces an HTTPS URI rather than a generic one.

## Accessing the parts

A `URI` value exposes its parts as members, which you read with dot notation:

| Member     | Description |
| ---------- | ----------- |
| `scheme`   | The scheme, such as `https` or `mailto`. |
| `userinfo` | The user information preceding `@` in the authority, such as `ann:secret`. |
| `host`     | The host name. |
| `port`     | The port, as an `Integer`. |
| `path`     | The path. |
| `query`    | The query string, without the leading `?`. |
| `fragment` | The fragment, without the leading `#`. |
| `opaque`   | The body of an opaque URI, such as the address in a `mailto:` URI. |

For example:

```puppet
$u = URI('https://ann:secret@example.com:8080/data?fmt=json#top')

notice($u.scheme)   # https
notice($u.host)     # example.com
notice($u.port)     # 8080
notice($u.path)     # /data
notice($u.query)    # fmt=json
notice($u.fragment) # top
```

Parts that the URI does not have are usually `undef`, so a `mailto:` URI has no host and a relative
reference has no scheme:

```puppet
notice(URI('mailto:ops@example.com').host =~ Undef) # true
notice(URI('/just/a/path').scheme =~ Undef) # true
```

Two parts do not follow that rule. Check them before you write an `Undef` constraint:

- `port` falls back to the registered default port for the scheme when the URI does not state one, so an
  `https` URI reports `443` and an `http` URI reports `80`. Only `ftp`, `http`, `https`, `ldap`, `ldaps`,
  `ws`, and `wss` have a registered default. For any other scheme, and for a URI with no scheme at all,
  `port` is `undef`.
- `path` is an empty string rather than `undef` when a hierarchical URI omits it. It is `undef` only for
  an opaque URI such as `mailto:`.

```puppet
notice(URI('https://example.com').port) # 443
notice(URI('https://example.com').path =~ Undef) # false, path is ''
notice(URI('ssh://example.com').port =~ Undef) # true, no default
notice(URI('/just/a/path').port =~ Undef) # true, no scheme
```

`port` is an `Integer`, not a string, so you can compare it numerically without converting it first.
{: .tip }

## Combining URIs

Use the `+` operator to resolve one URI against another. The right operand can be a `URI` or a string,
and OpenVox applies the usual URI resolution rules: a relative reference resolves against the base, while
an absolute path or a full URI replaces the corresponding parts.

```puppet
$base = URI('https://example.com/docs/')

notice($base + 'latest.html') # https://example.com/docs/latest.html
notice($base + '/other')      # https://example.com/other
notice($base + URI('/openvox')) # https://example.com/openvox
```

A trailing slash on the base changes the result, because a base path without one ends in a file rather
than a directory:

```puppet
$dir  = URI('https://example.com/docs/')
$file = URI('https://example.com/docs')

notice($dir + 'latest.html')  # https://example.com/docs/latest.html
notice($file + 'latest.html') # https://example.com/latest.html
```

Building URIs this way is safer than string concatenation, which cannot know whether the result needs a
separator.

## Converting URIs to strings

Interpolate a URI or pass it to `String` to get its string form back:

```puppet
$u = URI('https://example.com/a')

notice("${u}")      # https://example.com/a
notice(String($u))  # https://example.com/a
```

For more about converting between types, see [strings][strings] and the [`new` function][new function].

## The `URI` data type

The [data type][data type] of URI values is `URI`.

By default, `URI` matches any URI value. You can use parameters to restrict which values it matches.

### Parameters

The full signature for `URI` is:

```puppet
URI[<SPECIFIC URI OR HASH OF CONSTRAINTS>]
```

This parameter is optional.

| Position | Parameter   | Data Type          | Default Value | Description |
| -------- | ----------- | ------------------ | ------------- | ----------- |
| 1        | Constraints | `String` or `Hash` | none          | If specified, restricts the type to URIs whose parts match the given constraints. |

Given a string, `URI` constrains the parts that the string contains. This is not an exact match: parts the
string leaves out stay unconstrained, so a URI carrying extra parts still matches.

```puppet
$type = URI['https://example.com/a']

notice(URI('https://example.com/a') =~ $type)     # true
notice(URI('https://example.com/a?x=1') =~ $type) # true
notice(URI('https://example.com/b') =~ $type)     # false
```

Given a hash, `URI` constrains individual parts. The rules differ between the parts that hold strings and
`port`, which holds an `Integer`:

- The string parts (`scheme`, `userinfo`, `host`, `path`, `query`, `fragment`, and `opaque`) accept a
  string, a regular expression, an abstract data type such as [`Enum`][enum] or [`Pattern`][pattern], or
  [`NotUndef`][notundef] and `Undef` to require that the part is present or absent.
- `port` accepts a non-negative integer, an `Integer` range, `NotUndef`, or `Undef`. Giving it a string
  or a regular expression is an error, and `Enum` or `Pattern` never match, because the port is an
  `Integer` rather than a string.

```puppet
$u = URI('https://example.com:8443/a')

notice($u =~ URI[{scheme => 'https'}]) # true
notice($u =~ URI[{scheme => Enum['http', 'https']}]) # true
notice($u =~ URI[{host => /example/}]) # true
notice($u =~ URI[{host => NotUndef}]) # true
notice($u =~ URI[{port => Integer[8000, 9000]}]) # true
notice($u =~ URI[{port => 443}]) # false
```

The hash form is also how you require a part to be absent, which the string form cannot express:

```puppet
$strict = URI[{
  scheme => 'https',
  host   => 'example.com',
  path   => '/a',
  query  => Undef,
}]

notice(URI('https://example.com/a') =~ $strict)     # true
notice(URI('https://example.com/a?x=1') =~ $strict) # false
```

Requiring a part rejects URIs of the wrong shape. An opaque URI has no host, so it fails a `NotUndef`
host constraint:

```puppet
$has_host = URI[{host => NotUndef}]

notice(URI('mailto:ops@example.com') =~ $has_host) # false
```

This makes `URI` useful in class and defined type parameters, where it rejects malformed input before your
code runs:

```puppet
class profile::reporting (
  URI[{scheme => Enum['https'], host => NotUndef}] $endpoint,
) {
  $host = $endpoint.host
  notice("sending reports to ${host}")
}
```

### Examples

- `URI` --- matches any URI value.
- `URI['https://example.com/a']` --- matches URIs whose scheme, host, and path match those of
  `https://example.com/a`, regardless of any query or fragment.
- `URI[{scheme => 'https'}]` --- matches any HTTPS URI.
- `URI[{host => NotUndef}]` --- matches any URI that has a host, rejecting opaque URIs such as
  `mailto:`.
- `URI[{port => Integer[8000, 9000]}]` --- matches any URI whose port falls in that range.

### Related data types

`URI` is part of `RichData`, but it is not `Data` and not `Scalar`:

```puppet
$u = URI('https://example.com')

notice($u =~ RichData) # true
notice($u =~ Data)     # false
notice($u =~ Scalar)   # false
```

That matters when a parameter or function expects `Data`, which covers only the JSON-compatible types.

You can also use [abstract types][abstract types] to match values that might be a URI. For example,
`Optional[URI]` matches a URI or `undef`, and `Variant[URI, String]` matches a URI or a plain string.

The Puppet language specification describes the `URI` type in
[types, values, and variables](https://github.com/OpenVoxProject/puppet-specifications/blob/main/language/types_values_variables.md).
