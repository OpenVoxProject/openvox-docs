---
layout: default
title: "Language: Data types: Abstract data types"
---

[types]: ./lang_data_type.html
[data types]: ./lang_data.html
[strings]: ./lang_data_string.html
[regular expressions]: ./lang_data_regexp.html
[booleans]: ./lang_data_boolean.html
[arrays]: ./lang_data_array.html
[hashes]: ./lang_data_hash.html
[hash_missing_key_access]: ./lang_data_hash.html#accessing-values
[numbers]: ./lang_data_number.html
[semver]: ./lang_data_semver.html
[uri]: ./lang_data_uri.html
[time]: ./lang_data_time.html
[binary]: ./lang_data_binary.html
[error]: ./lang_data_error.html
[sensitive]: ./lang_data_sensitive.html
[typecasting]: ./lang_typecasting.html

As described in [the Data Type Syntax][types] page, each of Puppet's main [data types][] has a corresponding value that _represents_ that data type, which can be used to match values of that type in several contexts. (For example, `String` or `Array`.)

Each of those core data types will only match a particular set of values. They let you further restrict the values they'll match, but only in limited ways, and there's no way to _expand_ the set of values they'll match.

If you're using data types to match or restrict values and need more flexibility, you can use one of the _abstract data types_ on this page to construct a data type that suits your needs and matches the values you want.


## Flexible data types

These abstract data types can match values with a variety of concrete data types. Some of them are similar to a concrete type but offer alternate ways to restrict them (like `Enum`), and some of them let you combine types and match a union of what they would individually match (like `Variant` and `Optional`).

### `Optional`

The `Optional` data type wraps _one_ other data type, and results in a data type that matches anything that type would match _plus_ `undef`.

This is useful for matching values that are allowed to be absent.

It takes one mandatory parameter.

#### Parameters

The full signature for `Optional` is:

```puppet
Optional[<DATA TYPE>]
```

Position | Parameter        | Data Type | Default Value | Description
---------| -----------------|-----------|---------------|------------
1 | Data type | `Type` or `String` | none **(mandatory)** | The data type to add `undef` to.

`Optional` also allows you to specify a string as its parameter, which is a shortcut for `Optional[Enum["my string"]]` --- it will match only that exact string value or `undef`.

`Optional[<DATA TYPE>]` is equivalent to `Variant[ <DATA TYPE>, Undef ]`

#### Examples

* `Optional[String]` --- matches any string or `undef`.
* `Optional[Array[Integer[0, 10]]]` --- matches an array of integers between 0 and 10, or `undef`.
* `Optional["present"]` --- matches the exact string `"present"` or `undef`.


### `NotUndef`

The `NotUndef` type matches any value _except_ `undef`. It can also wrap one other data type, resulting in a type that matches anything the original type would match except `undef`.

It accepts one optional parameter.

#### Parameters

The full signature for `NotUndef` is:

```puppet
NotUndef[<DATA TYPE>]
```

Position | Parameter        | Data Type | Default Value | Description
---------| -----------------|-----------|---------------|------------
1 | Data type | `Type` or `String` | `Any` | The data type to subtract `undef` from.

`NotUndef` also allows you to specify a string as its parameter, which is a shortcut for `NotUndef[Enum["my string"]]` --- it will match only that exact string value. (This doesn't actually subtract anything, since the `Enum` wouldn't have matched `undef` anyway, but it enables a convenient notation for mandatory keys in `Struct` schema hashes.)

### `Variant`

The `Variant` data type combines any number of other data types, and results in a type that matches the union of what _any_ of those data types would match.

It takes any number of parameters, and requires at least one.

#### Parameters

The full signature for `Variant` is:

```puppet
Variant[ <DATA TYPE>, (<DATA TYPE, ...) ]
```

Position | Parameter        | Data Type | Default Value | Description
---------| -----------------|-----------|---------------|------------
1–∞ | Data type | `Type` | none **(mandatory)** | A data type to add to the resulting compound data type. You must provide at least one data type parameter, and can provide any number of additional ones.

#### Examples

* `Variant[Integer, Float]` --- matches any integer or floating point number (equivalent to `Numeric`).
* `Variant[Enum['true', 'false'], Boolean]` --- matches `'true'`, `'false'`, `true`, or `false`.


### `Pattern`

The `Pattern` data type only matches [strings][], but it provides an alternate way to restrict which strings it will match. It takes any number of [regular expressions][], and results in a data type that matches any strings that would match _any_ of those regular expressions.

It takes any number of parameters, and requires at least one.

#### Parameters

The full signature for `Pattern` is:

```puppet
Pattern[ <REGULAR EXPRESSION>, (<REGULAR EXPRESSION>, ...) ]
```

Position | Parameter        | Data Type | Default Value | Description
---------| -----------------|-----------|---------------|------------
1–∞ | Regular expression | `Regexp` | none **(mandatory)** | A regular expression describing some set of strings that the resulting data type should match. You must provide at least one regular expression parameter, and can provide any number of additional ones.


Note that you can use capture groups in the regular expressions, but they won't cause any variables like `$1` to be set.

#### Examples

* `Pattern[/\A[a-z].*/]` --- matches any string that begins with a lowercase letter.
* `Pattern[/\A[a-z].*/, /\Anone\Z/]` --- matches the above **or** the exact string `"none"`.


### `Enum`

The `Enum` data type only matches [strings][], but it provides an alternate way to restrict which strings it will match. It takes any number of strings, and results in a data type that matches any string values that _exactly_ match one of those strings. Unlike the `==` operator, this matching is case-sensitive.

It takes any number of parameters, and requires at least one.

#### Parameters

The full signature for `Enum` is:

```puppet
Enum[ <OPTION>, (<OPTION>, ...) ]
```

Position | Parameter        | Data Type | Default Value | Description
---------| -----------------|-----------|---------------|------------
1–∞ | Option | `String` | none **(mandatory)** | One of the literal string values that the resulting data type should match. You must provide at least one option parameter, and can provide any number of additional ones.


#### Examples

* `Enum['stopped', 'running']` --- matches the strings `'stopped'` and `'running'`, and no other values.
* `Enum['true', 'false']` --- matches the strings `'true'` and `'false'`, and no other values. Will not match the [boolean][booleans] values `true` or `false` (without quotes).


### `Tuple`

The `Tuple` type only matches [arrays][], but it lets you specify different data types for _every element_ of the array, in order.

It takes any number of parameters, and requires at least one.

#### Parameters

The full signature for `Tuple` is:

```puppet
Tuple[ <CONTENT TYPE>, (<CONTENT TYPE>, ..., <MIN SIZE>, <MAX SIZE>) ]
```

Position | Parameter        | Data Type | Default Value | Description
---------| -----------------|-----------|---------------|------------
1–∞ | Content type | `Type` | none **(mandatory)** | What kind of values the array contains _at the given position._ You must provide at least one content type parameter, and can provide any number of additional ones.
-2 | Min size | `Integer` | # of content types | The minimum number of elements in the array. If this is smaller than the number of content types you provided, any elements beyond the minimum will be optional; however, if present, they must still match the provided content types. This parameter accepts the special value `default`, but this won't use the default value; instead, it means 0 (all elements optional).
-1 | Max size | `Integer` | # of content types | The maximum number of elements in the array. You cannot specify a max without also specifying a min. If the max is larger than the number of content types you provided, it means the array can contain any number of additional elements, which _all_ must match the _last_ content type. This parameter accepts the special value `default`, but this won't use the default value; instead, it means infinity (any number of elements matching the final content type).

Note that if the max is _smaller_ than the number of content types you provided, it's nonsensical.

#### Examples

* `Tuple[String, Integer]` --- matches a two-element array containing a string followed by an integer, like `["hi", 2]`.
* `Tuple[String, Integer, 1]` --- matches the above **or** a one-element array containing only a string.
* `Tuple[String, Integer, 1, 4]` --- matches an array containing one string followed by 0 to 3 integers.
* `Tuple[String, Integer, 1, default]` --- matches an array containing one string followed by any number of integers.

### `Struct`

The `Struct` type only matches [hashes][], but it lets you specify:

* The name of every allowed key.
* Whether each key is required or optional.
* The allowed data type for each of those keys' values.

It takes one mandatory parameter.

#### Parameters

The full signature for `Struct` is:

```puppet
Struct[<SCHEMA HASH>]
```

Position | Parameter        | Data Type | Default Value | Description
---------| -----------------|-----------|---------------|------------
1 | Schema hash | `Hash[Variant[String, Optional, NotUndef], Type]` | none **(mandatory)** | A hash that has all of the allowed keys and data types for the struct.


#### Schema hashes

A struct's schema hash must have the same keys as the hashes it will match. Each value must be a [data type][types] that matches the allowed values for that key.

The keys in a schema hash are usually strings. They can also be an `Optional` or `NotUndef` type with the key's name as their parameter.

If a key is a string, Puppet uses the _value's_ type to determine whether it's optional --- since [accessing a missing key resolves to the value `undef`][hash_missing_key_access], the key will be optional if the value type accepts `undef` (like `Optional[Array]`).

Note that this doesn't distinguish between an explicit value of `undef` and an absent key. If you want to be more explicit, you can use `Optional['my_key']` to indicate that a key can be absent, and `NotUndef['my_key']` to make it mandatory. If you use one of these, a value type that accepts `undef` will only be used to decide about explicit `undef` values, not missing keys.

#### Examples

```puppet
Struct[{mode => Enum[read, write, update],
        path => String[1]}]
```

This data type would match hashes like `{mode => 'read', path => '/etc/fstab'}`. Both the `mode` and `path` keys are mandatory; `mode`'s value must be one of `'read', 'write',` or `'update'`, and `path` must be a string of at least one character.

```puppet
Struct[{mode => Enum[read, write, update],
        path => Optional[String[1]]}]
```

This data type would match the same values as the previous example, but the `path` key is optional. If present, `path` must match `String[1]` or Undef.

```puppet
Struct[{mode            => Enum[read, write, update],
        path            => Optional[String[1]],
        Optional[owner] => String[1]}]
```

In this data type, the `owner` key can be absent, but if it's present, it _must_ be a string; a value of `undef` isn't allowed.

```puppet
Struct[{mode            => Enum[read, write, update],
        path            => Optional[String[1]],
        NotUndef[owner] => Optional[String[1]]}]
```

In this data type, the owner key is mandatory, but it allows an explicit `undef` value.

## Parent types

These abstract data types are the parents of multiple other types, and match values that would match _any_ of their sub-types. They're mostly useful when you have very loose restrictions but still want to guard against something weird.

### `Scalar`

The `Scalar` data type matches _all_ values of the following concrete data types:

* [Numbers][] (both integers and floats)
* [Strings][]
* [Booleans][]
* [Regular expressions][]
* [`SemVer` and `SemVerRange`][semver]
* [`Timestamp` and `Timespan`][time]

Note that it doesn't match `undef`, `default`, resource references, arrays, or hashes.

It takes no parameters.

### `ScalarData`

The `ScalarData` data type matches the subset of `Scalar` that can be represented directly in JSON:

* [Numbers][] (both integers and floats)
* [Strings][]
* [Booleans][]

It doesn't match regular expressions, `SemVer`, `SemVerRange`, `Timestamp`, or `Timespan`, all of which
`Scalar` does match. Like `Scalar`, it doesn't match `undef` or `default`.

It takes no parameters.

`ScalarData` is to `Scalar` what `Data` is to `RichData`: the JSON-compatible subset.

### `Data`

The `Data` data type matches any value that would match `ScalarData`, but it also matches:

* `undef`
* [Arrays][] that only contain values that would also match `Data`
* [Hashes][] whose keys are [strings][] and whose values would also match `Data`

Note that it is built on `ScalarData` rather than `Scalar`, so the members of `Scalar` that have no JSON
equivalent are excluded: a regular expression matches `Scalar` but not `Data`. It also doesn't match
`default` or resource references.

It takes no parameters.

`Data` is especially useful because it represents the subset of types that can be directly represented in almost all serialization formats (e.g. JSON).

### `RichData`

The `RichData` data type matches any value that would match `Data`, and also matches the types that have no
direct JSON equivalent:

* [Regular expressions][]
* [`URI`][uri]
* [`Binary`][binary]
* [`Timestamp` and `Timespan`][time]
* [`SemVer` and `SemVerRange`][semver]
* [`Error`][error]
* [`Sensitive`][sensitive]
* Data types themselves, such as `Integer`
* Resource and class references
* `default`
* [Arrays][] and [hashes][] containing any of the above

It takes no parameters.

`RichData` is what a parameter or function should accept when it needs to handle any ordinary Puppet value.
Use `Data` instead when the value has to survive being serialized to JSON, and note that this is the
distinction that makes `Error('boom') =~ Data` false while `Error('boom') =~ RichData` is true.

### `Collection`

The `Collection` type matches _any_ array or hash, regardless of what kinds of values (and/or keys) it contains.

Note that this means it only partially overlaps with `Data` --- there are values (like an array of resource references) that match `Collection` but will not match `Data`.

`Collection` is equivalent to `Variant[Array[Any], Hash[Any, Any]]`.

### `Iterable`

The `Iterable` data type matches any value that an iterative function such as `each` or `map` can walk over.
That includes arrays, hashes, strings, integers, and the `Iterator` values described below:

```puppet
notice([1, 2] =~ Iterable)  # true
notice({'a' => 1} =~ Iterable) # true
notice('abc' =~ Iterable)   # true
notice(5 =~ Iterable)       # true
notice(undef =~ Iterable)   # false
```

An optional parameter constrains what the value iterates over, so `Iterable[Integer]` matches only things
that yield integers:

```puppet
notice(5 =~ Iterable[Integer]) # true
```

### `Iterator`

The `Iterator` data type matches the lazy sequences produced by the chained forms of some iterative
functions, such as `reverse_each` and `step` called without a block. Every `Iterator` is also `Iterable`,
but ordinary arrays and hashes are not `Iterator`:

```puppet
notice([1, 2].reverse_each =~ Iterator) # true
notice([1, 2] =~ Iterator)              # false
```

Like `Iterable`, it accepts an optional parameter for the type it yields. You rarely write `Iterator`
yourself; it matters mainly when a function returns one and you want to constrain what it produces.

### `Catalogentry`

The `Catalogentry` data type is the parent type of `Resource` and `Class`. This means that, like those types, the Puppet language contains no values that it will ever match. However, the type `Type[Catalogentry]` will match any class reference or resource reference.

It takes no parameters.

### `Any`

The `Any` data type matches _any_ value of _any_ data type.

## Unusual types

These types aren't quite like the others.

### `Callable`

The `Callable` data type matches callable lambdas provided as function arguments.

There is no way to interact with `Callable` values in the Puppet language, but Ruby functions written to the modern function API (`Puppet::Functions`) can use this data type to inspect the lambda provided to the function.

#### Parameters

The full signature for `Callable` is:

```puppet
Callable[ (<DATA TYPE>, ...,) <MIN COUNT>, <MAX COUNT>, <BLOCK TYPE> ]
```

All of these parameters are optional.

Position | Parameter | Data Type | Default Value | Description
---------|-----------|-----------|---------------|------------
1–∞      | Data type | `Type`    | none          | Any number of data types, representing the data type of each argument the lambda accepts.
-3 | Min count | `Integer` | 0 | The minimum number of arguments the lambda accepts. This parameter accepts the special value `default`, which will use its default value.
-2 | Max count | `Integer` | infinity | The maximum number of arguments the lambda accepts. This parameter accepts the special value `default`, which will use its default value.
-1 | Block type | `Type[Callable]` | none | The `block_type` of the lambda.

### `Init`

The `Init` data type matches values that can be used as the initialization/typecase of another data type given as a parameter. This can be used to test if a value can be converted to the wanted data type.

#### Parameters

The signature for `Init` is:

```puppet
Init[ <DATA TYPE> ]
```

#### Examples

Check if a string value can be converted to a `SemVer`:

```puppet
"1.2.3" =~ Init[SemVer]    # result is true
"latest" =~ Init[SemVer]   # result is false
```

Check if a value can be converted to an `Integer`:

```puppet
"10" =~ Init[Integer]    # result is true
"blue" =~ Init[Integer]  # result is false
```

Accept a parameter value that is either an `Integer` or a value convertible to one:

```puppet
function example(Variant[Integer, Init[Integer]] $x) {
   $int_value = Integer($x)  # Safe conversion
}
```

See [typecasting][] for the conversions `Init` tests against.

### `Runtime`

The `Runtime` data type matches values that belong to the implementation language underneath Puppet rather
than to the Puppet language itself. It takes the runtime name and the type name within it:

```puppet
Runtime['ruby', 'Symbol']
```

You cannot create such a value in a manifest. The type exists so that Ruby functions and types can describe
arguments that are Ruby objects with no Puppet equivalent, and so those arguments can be type-checked.

### `Object`

The `Object` data type is the parent of types created with the Pcore object model, which is how modules
define types that have named attributes and their own methods. An object type is declared by passing a hash
that names it and lists its attributes:

```puppet
$greeter = Object[{name => 'Greeter', attributes => {greeting => String}}]
$g = $greeter.new('hello')

notice($g.greeting)    # hello
notice($g =~ $greeter) # true
```

In practice you rarely write this form inline. Modules declare object types in their `types` directory, one
type per file.

### `TypeSet`

The `TypeSet` data type groups several object types together under one name and version, so a module can
publish a related family of types rather than a loose collection. A type set records a name, a version, and
the types it contains.

A module publishes one by declaring it in `types/init_typeset.pp`, which OpenVox loads as the type set named
after the module. Type sets are not written inline in a manifest.

The type parser accepts any capitalization, so `Typeset` also works, but `TypeSet` is the spelling OpenVox
itself uses when it renders the type.
