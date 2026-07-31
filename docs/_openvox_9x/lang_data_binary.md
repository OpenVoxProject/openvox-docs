---
layout: default
title: "Language: Data types: Binary"
---

[abstract types]: lang_data_abstract.html
[data type]: lang_data_type.html
[new function]: function.html#new
[strings]: lang_data_string.html
[array]: lang_data_array.html

A `Binary` value is a sequence of 8-bit bytes. Use it when you are handling raw binary content, such as
the bytes of an image, a certificate, or any data that is not text. A `Binary` keeps the exact bytes it was
given, which a string cannot always do, because a string carries an encoding and assumes its contents are
valid text.

A `Binary` is not a string of base64 text. Base64 is only how a `Binary` is written down and read back: you
construct one from a base64 string, and it prints itself as base64, but the value in between is the decoded
bytes.

## Syntax

Construct a `Binary` with either the short form `Binary(...)` or `Binary.new(...)`. Both call the
[`new` function][new function]:

```puppet
$abc  = Binary('YWJj')
$same = Binary.new('YWJj')

notice(String($abc, '%s')) # abc
```

The string is decoded as strict base64 by default, so `'YWJj'` becomes the three bytes of `abc`.

### Choosing a base64 format

A second argument selects how the string is read. The default is `%B`.

| Format | How the string is read |
| ------ | ---------------------- |
| `%B`   | Strict base64 (RFC 4648). Padding must be correct and line breaks are an error. This is the default. |
| `%b`   | Standard base64. Missing padding is added for you, and line breaks are allowed. |
| `%u`   | URL- and filename-safe base64, which uses `-` and `_` in place of `+` and `/`. |
| `%s`   | Not base64 at all. The string's own characters are taken as its UTF-8 bytes. The string must be valid text. |
| `%r`   | Not base64 at all. The string's raw bytes are used exactly as given. |

The `%s` and `%r` formats build a `Binary` from a string's bytes rather than by decoding base64, so use them
when you already hold the content you want as bytes:

```puppet
notice(Binary('abc', '%s') == Binary('YWJj')) # true
```

Reach for `%r` only when a function hands you a string that is really binary content. Code that produces such
data should return a `Binary` instead.

### Creating a Binary from bytes

You can also build a `Binary` from an [array][] of byte values, each an integer from 0 to 255:

```puppet
notice(Binary([97, 98, 99]) == Binary('YWJj')) # true
```

### Creating a Binary from a hash

The hash form takes the same inputs as a `value` key, with an optional `format` for the string case. It is
useful when you assemble the arguments from data:

```puppet
notice(Binary({'value' => 'YWJj'}) == Binary('YWJj'))                 # true
notice(Binary({'value' => 'abc', 'format' => '%s'}) == Binary('YWJj')) # true
notice(Binary({'value' => [97, 98, 99]}) == Binary('YWJj'))           # true
```

## Accessing the bytes

`length` returns the number of bytes, and you can index into a `Binary` to read part of it:

```puppet
$b = Binary('YWJj') # the bytes for abc

notice($b.length)              # 3
notice(String($b[0], '%s'))   # a
notice(String($b[1, 2], '%s')) # bc
notice(String($b[-1], '%s'))  # c
```

Indexing returns another `Binary`, not an integer. `$b[0]` is a one-byte `Binary`, and `$b[offset, count]`
is the slice of `count` bytes starting at `offset`. To get byte values as numbers instead, convert the whole
`Binary` to an array, as shown below.

## Converting a Binary to a string or array

Pass a `Binary` to `String` to get base64 text, or interpolate it to get the same strict base64 form. Give
`String` a format to choose another representation:

```puppet
$b = Binary('YWJj')

notice("${b}")           # YWJj
notice(String($b))       # YWJj
notice(String($b, '%s')) # abc
notice(String($b, '%p')) # Binary("YWJj")
```

`%s` returns the bytes as characters, which is an error unless they are valid UTF-8. `%p` returns the
`Binary("...")` form that the Puppet language can parse back into a value.

Pass a `Binary` to `Array` to get its bytes as integers:

```puppet
notice(Array(Binary('YWJj'))) # [97, 98, 99]
```

For more about converting between types, see [strings][strings] and the [`new` function][new function].

## Reading binary content from a file

The `binary_file` function reads a file from a module and returns its contents as a `Binary`, which is the
usual way to load real binary data:

```puppet
$logo = binary_file('mymodule/logo.png')
```

A `Binary` serializes as base64 when the report or catalog format is textual, such as JSON or YAML, and as
raw bytes when the format supports them. You do not have to encode or decode it yourself.
{: .tip }

## The `Binary` data type

The [data type][data type] of a `Binary` value is `Binary`. It matches any `Binary` value and takes no
parameters.

### Examples

- `Binary` --- matches any `Binary` value.
- `Optional[Binary]` --- matches a `Binary` or `undef`.
- `Variant[Binary, String]` --- matches a `Binary` or a plain string, which is useful for a parameter that
  accepts either raw bytes or base64 text.

### Related data types

`Binary` is part of `RichData`, but it is not `Data`, `Scalar`, or `ScalarData`:

```puppet
$b = Binary('YWJj')

notice($b =~ RichData)   # true
notice($b =~ Data)       # false
notice($b =~ Scalar)     # false
notice($b =~ ScalarData) # false
```

That matters when a parameter or function expects `Data`, which covers only the JSON-compatible types. A
`Binary` is not one of them, even though it serializes to a base64 string, so pass it where `RichData` or
`Binary` is accepted.

You can also use [abstract types][abstract types] to match values that might be a `Binary`. For example,
`Optional[Binary]` matches a `Binary` or `undef`.
