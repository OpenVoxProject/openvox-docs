---
layout: default
title: "Language: Data types: Error"
---

[data type]: lang_data_type.html
[abstract types]: lang_data_abstract.html
[hash]: lang_data_hash.html
[enum]: lang_data_abstract.html#enum
[pattern]: lang_data_abstract.html#pattern
[notundef]: lang_data_abstract.html#notundef
[case statements]: lang_conditional.html#case-statements

An `Error` value describes an error condition as data. It carries a message, and optionally a `kind` that
names the category of error, an `issue_code`, and a hash of `details`. This lets code that can fail report an
error as a value you can inspect and categorize, rather than only aborting the run.

## Creating an Error

The short form takes a message, and optionally a kind:

```puppet
$e = Error('The config file is missing')

notice($e.message) # The config file is missing
```

```puppet
$e = Error('The config file is missing', 'mymod/missing-file')

notice($e.kind) # mymod/missing-file
```

To set an issue code or details as well, use the hash form, which names each part. Only `msg` is required:

```puppet
$e = Error({
  'msg'        => 'The config file is missing',
  'kind'       => 'mymod/missing-file',
  'issue_code' => 'E100',
  'details'    => {'path' => '/etc/myapp.conf'},
})

notice($e.issue_code)        # E100
notice($e.details['path'])   # /etc/myapp.conf
```

## Reading an error's parts

An `Error` exposes its parts as members. `message` is the same as `msg`. The parts you did not set are
`undef`:

| Member       | Description |
| ------------ | ----------- |
| `message`    | The error message. Same as `msg`. |
| `msg`        | The error message. |
| `kind`       | The category of error, such as `mymod/missing-file`, or `undef`. |
| `issue_code` | A code identifying the specific issue, which can be used to translate the message into other locales, or `undef`. |
| `details`    | A [hash][hash] of extra information, typed as `Hash[String[1], Data]`, or `undef`. |

```puppet
$e = Error('Something failed')

notice($e.message)         # Something failed
notice($e.kind =~ Undef)   # true, no kind was set
```

## The `Error` data type

The [data type][data type] of an error value is `Error`. On its own it matches any error.

### Parameters

`Error` takes an optional `kind`, and an optional `issue_code` after it. Each restricts the type to errors
whose `kind` or `issue_code` matches. A parameter can be a string for an exact match, a regular expression,
or an abstract type such as [`Enum`][enum], [`Pattern`][pattern], or [`NotUndef`][notundef].

```puppet
$e = Error('Bad value', 'mymod/type-mismatch')

notice($e =~ Error) # true
notice($e =~ Error['mymod/type-mismatch']) # true, kind matches
notice($e =~ Error['mymod/other']) # false
notice($e =~ Error[Pattern[/^mymod/]]) # true, kind matches
notice($e =~ Error[NotUndef]) # true, has a kind
```

This makes `Error` useful for sorting errors by category, for example in a [case statement][case statements]
that handles each `kind` differently:

```puppet
$err = Error('Config file missing', 'mymod/config')

$handled = $err ? {
  Error['mymod/config']  => 'config problem',
  Error['mymod/network'] => 'network problem',
  default                => 'unknown problem',
}

notice($handled) # config problem
```

### Examples

- `Error` --- matches any error.
- `Error['mymod/missing-file']` --- matches an error with that exact kind.
- `Error[Pattern[/^mymod/]]` --- matches an error whose kind starts with `mymod`.
- `Error[NotUndef]` --- matches any error that has a kind.
- `Error['mymod/missing-file', 'E100']` --- matches on both kind and issue code.

### Related data types

`Error` is part of `RichData`, but it is not `Data`, `Scalar`, or `ScalarData`:

```puppet
$e = Error('boom')

notice($e =~ RichData)   # true
notice($e =~ Data)       # false
notice($e =~ Scalar)     # false
notice($e =~ ScalarData) # false
```

That matters when a parameter or function expects `Data`, which covers only the JSON-compatible types. Use
`RichData`, or `Error` itself, when you need to accept one.

You can also use [abstract types][abstract types] to match a value that might be an error. For example,
`Optional[Error]` matches an `Error` or `undef`, and `Variant[Error, String]` matches an error or a plain
string message.
