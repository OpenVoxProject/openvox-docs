---
layout: default
title: "Language: Typecasting"
---

[data type]: lang_data_type.html
[data types]: lang_data_type.html
[new function]: function.html#new
[scanf function]: function.html#scanf
[strings]: lang_data_string.html
[numbers]: lang_data_number.html
[booleans]: lang_data_boolean.html
[arrays]: lang_data_array.html
[hashes]: lang_data_hash.html
[abstract types]: lang_data_abstract.html
[regexp]: lang_data_regexp.html
[binary]: lang_data_binary.html
[time]: lang_data_time.html

Every value in the Puppet language has a [data type][], and converting between types is something you ask
for rather than something Puppet does for you. When you have a string that holds a number, or an array of
pairs that ought to be a hash, you convert it by asking for a new value of the type you want.

Converting never changes the original value. It produces a new value, leaving the one you started with
alone.

Two things do convert without being asked: arithmetic on a string that looks like a number, and string
interpolation. Both are covered in [automatic coercion](#automatic-coercion) below.

## Calling a data type as a constructor

To convert a value, call the target data type as though it were a function, passing the value you want to
convert:

```puppet
notice(Integer('42'))  # 42
notice(Boolean('yes')) # true
notice(String(42))     # 42
```

Calling a data type this way is exactly the same as calling the [`new` function][new function] on it. These
two lines do the same thing:

```puppet
$a = Integer.new('42')
$b = Integer('42')
```

Most people find the shorter form easier to read, so the rest of this page uses it.

Some conversions take extra arguments. You can pass them by position, or by name using a hash:

```puppet
notice(Integer('42', 8))                        # 34
notice(Integer({'from' => '42', 'radix' => 8})) # 34
```

Both of those read the string `'42'` as an octal number, giving the decimal value 34.

If the data type has constraints, the converted value is checked against them and an error is raised if it
doesn't fit. For example, `Integer[0]` only accepts values of zero or more:

```puppet
Integer[0]('-100')
# Error: Converted value from Integer[0].new() has wrong
# type, expects an Integer[0] value, got Integer[-100, -100]
```

You cannot construct most [abstract types][], such as `Variant`. `Optional[T]` and `NotUndef[T]` are
exceptions: they convert exactly as their type argument `T` does, and `Optional[T]` also accepts `undef`:

```puppet
notice(Optional[Integer]('42')) # 42
notice(Optional[Integer](undef) =~ Undef) # true
```

## Converting to numbers

For what the resulting values can do once you have them, see [numbers][].

### Integer

`Integer` accepts strings, floats, and booleans. When converting a string, you can give a radix (base) as a
second argument:

```puppet
notice(Integer('0xFF', 16)) # 255
notice(Integer('010', 10))  # 10
```

If you don't specify a radix, Puppet detects it from the start of the string: a leading `0b` or `0B` means
binary, `0x` or `0X` means hexadecimal, and a leading `0` means octal. Everything else is decimal. Passing
`default` as the radix asks for this same detection explicitly.

```puppet
notice(Integer('010'))    # 8
notice(Integer('0b1011')) # 11
notice(Integer('-42'))    # -42
```

Converting a float truncates the fraction rather than rounding it, and a boolean becomes `1` or `0`:

```puppet
notice(Integer(3.99))  # 3
notice(Integer(-3.99)) # -3
notice(Integer(true))  # 1
notice(Integer(false)) # 0
```

A third argument of `true` makes the result absolute:

```puppet
notice(Integer(-38, 10, true)) # 38
```

### Float and Numeric

`Float` always produces a float, adding a `.0` fraction to whole numbers:

```puppet
notice(Float('3.14')) # 3.14
notice(Float(3))      # 3.0
notice(Float(true))   # 1.0
notice(Float('0xFF')) # 255.0
```

`Numeric` picks the type to suit the value. A value with a decimal point or an exponent becomes a float,
and anything else becomes an integer:

```puppet
notice(Numeric('3.14')) # 3.14
notice(Numeric('1e3'))  # 1000.0
notice(Numeric('0xFF')) # 255
notice(Numeric(true))   # 1
```

Both accept an extra `true` argument to return an absolute value:

```puppet
notice(Numeric('-42.3'))     # -42.3
notice(Numeric(-42.3, true)) # 42.3
```

> **Note:** conversion to a number is strict about the text it accepts. A string with surrounding whitespace,
> such as `'  42  '`, cannot be converted, and neither can `undef`. Both raise an error rather than
> returning a default. If you need to tolerate stray text, see
> [extracting numbers from strings](#extracting-numbers-from-strings) below.

## Converting to strings

`String` converts any value, including arrays and hashes, into a [string][strings]:

```puppet
notice(String(42))      # 42
notice(String(true))    # true
notice(String([1,2,3])) # [1, 2, 3]
```

A second argument gives a format directive controlling how the value is rendered:

```puppet
notice(String(255, '%x'))       # ff
notice(String(255, '%#x'))      # 0xff
notice(String(3.14159, '%.2f')) # 3.14
```

Two defaults are worth knowing. A float with no format is rendered with six decimal places, and `undef`
becomes an empty string:

```puppet
notice(String(1.0))            # 1.000000
notice(String(undef) == '')    # true
```

`String` accepts a large set of format directives, and can take a hash mapping data types to formats so that
values inside an array or hash are each rendered differently. For the full set, see the
[`new` function][new function].

## Converting to booleans

Unlike some languages, Puppet has no notion of "truthy" values to fall back on, so conversion to a
[boolean][booleans] accepts a small, fixed vocabulary. The strings `'true'`, `'yes'`, and `'y'` become `true`, and
`'false'`, `'no'`, and `'n'` become `false`. The comparison ignores case:

```puppet
notice(Boolean('true')) # true
notice(Boolean('YES'))  # true
notice(Boolean('No'))   # false
```

For numbers, zero is `false` and everything else, including negative numbers, is `true`:

```puppet
notice(Boolean(0))   # false
notice(Boolean(0.0)) # false
notice(Boolean(1))   # true
notice(Boolean(-1))  # true
```

Any other string raises an error, so `Boolean('maybe')` fails rather than guessing.

## Converting between arrays and hashes

[Arrays][arrays] and [hashes][hashes] convert into one another, which is a common need when data arrives in
one shape and your code expects the other.

### To an array

A hash becomes an array of key/value pairs:

```puppet
notice(Array({'a' => 1, 'b' => 2}))
# [[a, 1], [b, 2]]
```

An array is returned unchanged, an empty hash becomes an empty array, and a [`Binary`][binary] becomes an
array of byte values:

```puppet
notice(Array(Binary('aGk='))) # [104, 105]
```

Anything iterable is turned into an array of the things it iterates over, which is easy to trip over. A
string iterates over its characters, and an integer iterates over the numbers below it:

```puppet
notice(Array('hello')) # [h, e, l, l, o]
notice(Array(1))       # [0]
```

When what you actually want is "wrap this in an array unless it already is one", pass a second argument of
`true`:

```puppet
notice(Array('hello', true)) # [hello]
notice(Array([1, 2], true))  # [1, 2]
```

Note that `undef` wraps to an empty array, not to an array containing `undef`:

```puppet
notice(Array(undef, true)) # []
```

### To a hash

An array of pairs becomes a hash, and so does a flat array with an even number of entries:

```puppet
notice(Hash([['a', 1], ['b', 2]])) # {a => 1, b => 2}
notice(Hash(['a', 1, 'b', 2]))     # {a => 1, b => 2}
```

An empty array becomes an empty hash, and a hash is returned unchanged. An array with an odd number of
entries raises an `odd number of arguments for Hash` error.

### Tuple and Struct

`Tuple` converts exactly as `Array` does, and `Struct` exactly as `Hash` does. The difference is that the
result is then checked against the type you asked for:

```puppet
notice(Tuple[String, Integer](['a', 1])) # [a, 1]
notice(Struct[{'a' => Integer}]([['a', 1]])) # {a => 1}
```

## Extracting numbers from strings

Conversion requires the whole string to be a number. To pull a number out of a longer piece of text, use the
[`scanf` function][scanf function], which takes a format and always returns an array of what it found:

```puppet
notice(scanf('42 apples', '%d')) # [42]
notice('2.5kg'.scanf('%f'))      # [2.5]
```

If nothing matches, you get an empty array rather than an error, which makes `scanf` a good way to handle
input that might not contain a number at all:

```puppet
notice(scanf('no digits', '%d')) # []
```

## Automatic coercion

Arithmetic operators can coerce a string to a number, but by default OpenVox treats doing so as an error:

```puppet
notice('1' + 1)
# Error: The string '1' was automatically coerced to the
# numerical value 1
```

This is controlled by the `strict` setting, which defaults to `error`. Setting it to `warning` lets the
arithmetic proceed and logs a warning instead; setting it to `off` silences the message entirely. Rather
than relaxing the setting, convert explicitly, which works under any value of `strict`:

```puppet
notice(Integer('1') + 1) # 2
```

String interpolation is a separate matter and is always allowed. Putting a value in a string converts it
without complaint:

```puppet
$n = 42
notice("interpolated:${n}") # interpolated:42
```

## Other conversions

A string becomes a [`Regexp`][regexp], which is useful when the pattern is built at runtime or comes from
data:

```puppet
$r = Regexp('[a-z]+\.com')
notice('foo.com' =~ $r) # true
```

A string naming a data type becomes that data type:

```puppet
notice(Type('Integer') == Integer) # true
```

The [`Timestamp` and `Timespan`][time] types have their own rich set of conversions from strings, numbers,
and hashes, covered on their own page.

## Further reading

* The [`new` function][new function] documents every conversion signature in full, including the complete
  list of string format directives.
* [Data type syntax][data types] covers how data types are written and where you can use them.
* [Abstract data types][abstract types] covers `Optional`, `NotUndef`, `Variant`, and the rest.
