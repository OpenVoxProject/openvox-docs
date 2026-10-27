---
layout: default
title: "Language: Data types: Timestamp and Timespan"
---

[data type]: lang_data_type.html
[new function]: function.html#new
[strftime]: function.html#strftime
[abstract types]: lang_data_abstract.html

OpenVox has two related data types for working with time. A `Timestamp` is a specific moment, such as when a
run happened. A `Timespan` is a length of time, such as how long something took or how old a file is allowed
to be. Subtracting one `Timestamp` from another gives a `Timespan`, and adding a `Timespan` to a `Timestamp`
gives another `Timestamp`.

Both are precise to the nanosecond. A `Timestamp` is stored as an instant in UTC, so a value keeps its
meaning regardless of the time zone it was parsed from or printed in.

## Timestamp

### Creating a Timestamp

Call `Timestamp` with no arguments, or `Timestamp.new`, to get the current time:

```puppet
$now = Timestamp()

notice($now =~ Timestamp) # true
```

Give it a number to interpret it as seconds since the Unix epoch (1970-01-01 00:00:00 UTC). A float carries
fractions of a second:

```puppet
notice(Timestamp(1473150899)) # 2016-09-06T08:34:59.000000000 UTC
```

Give it a string to parse it. With no format, the string is read as ISO 8601 and assumed to be UTC:

```puppet
notice(Timestamp('2016-08-24T12:13:14'))
# 2016-08-24T12:13:14.000000000 UTC
```

To parse another layout, pass a format string, and optionally a time zone that the string is assumed to be
in. The result is still stored in UTC:

```puppet
notice(Timestamp('2016-08-24 12:13:14', '%F %T', 'PST'))
# 2016-08-24T20:13:14.000000000 UTC
```

The format uses `strftime` directives such as `%Y`, `%m`, `%d`, `%H`, `%M`, and `%S`, plus shorthands like
`%F` for `%Y-%m-%d` and `%T` for `%H:%M:%S`. For the full set of directives, and for passing an array of
formats to try in turn, see the [`new` function][new function]. You can also pass the arguments as a hash:

```puppet
notice(Timestamp({'string' => '2015', 'format' => '%Y'}))
# 2015-01-01T00:00:00.000000000 UTC
```

### Formatting a Timestamp

Interpolating a `Timestamp`, or passing it to `String`, gives the full nanosecond UTC form. To choose a
layout, use the [`strftime` function][strftime] or the `strftime` member, which take the same directives as
the parser:

```puppet
$ts = Timestamp('2016-01-01T08:30:00')

notice(String($ts))              # 2016-01-01T08:30:00.000000000 UTC
notice($ts.strftime('%Y-%m-%d')) # 2016-01-01
notice(strftime($ts, '%Y'))      # 2016
```

Passing a `strftime` directive to `String`, as in `String($ts, '%Y')`, does not work: `String` reserves `%`
for its own format flags. Use `strftime` for date and time layouts.
{: .tip }

## Timespan

### Creating a Timespan

Give `Timespan` a number to interpret it as seconds, with a float carrying fractions of a second:

```puppet
notice(Timespan(13.5)) # 0-00:00:13.5
```

Give it separate fields in the order days, hours, minutes, seconds, and optionally milliseconds,
microseconds, and nanoseconds:

```puppet
notice(Timespan(4, 0, 0, 2)) # 4-00:00:02.0 (4 days, 2 s)
```

The hash form takes the same fields by name, which is clearer when you only set one or two. It also accepts
`negative => true` for a negative duration:

```puppet
notice(Timespan({'days' => 4})) # 4-00:00:00.0
```

You can also parse a string. The `Timespan` format directives are `%D` for days, `%H` for hours, `%M` for
minutes, `%S` for seconds, `%L` for milliseconds, and `%N` for fractional-second digits. With no format, a
set of default patterns is tried:

```puppet
notice(Timespan('13:20:00')) # 0-13:20:00.0 (13h 20m)
```

The default patterns all include seconds, so a string like `'13:20'` does not parse on its own. Either write
the seconds, as above, or pass an explicit format such as `Timespan('13:20', '%H:%M')`.
{: .tip }

### Formatting a Timespan

As with `Timestamp`, `String` gives the default form and `strftime` gives a chosen layout. The
highest-magnitude directive in the format absorbs any overflow, so a duration longer than a day still prints
its hours when the format has no `%D`:

```puppet
$d = Timespan({'hours' => 25, 'minutes' => 5})

notice(String($d))           # 1-01:05:00.0
notice($d.strftime('%H:%M')) # 25:05
```

## Doing arithmetic with times

The two types work together under the usual operators:

```puppet
$start = Timestamp('2016-01-01T00:00:00')
$end   = Timestamp('2016-01-02T06:00:00')

notice($end - $start)               # 1-06:00:00.0, a Timespan
notice(($end - $start) =~ Timespan) # true
notice($start + Timespan({'hours' => 12})) # noon on 2016-01-01
notice($start < $end)               # true
```

- Subtracting one `Timestamp` from another gives the `Timespan` between them.
- Adding or subtracting a `Timespan` moves a `Timestamp` forwards or backwards.
- Adding or subtracting two `Timespan` values gives another `Timespan`.
- Both types compare with `<`, `>`, `<=`, `>=`, `==`, and `!=`.

Passing either type to `Integer` or `Float` gives seconds: for a `Timestamp`, seconds since the epoch, and
for a `Timespan`, its total length.

```puppet
notice(Integer(Timestamp('2016-01-01T00:00:00'))) # 1451606400
notice(Integer(Timespan({'minutes' => 2})))       # 120
```

## The `Timestamp` and `Timespan` data types

The [data type][data type] of an instant is `Timestamp`, and the [data type][data type] of a duration is
`Timespan`. On its own, each matches any value of that type.

### Parameters

Both take an optional range as a lower and upper bound, written the same way you would construct a value.
`Timestamp[from, to]` matches instants in the range, and `Timespan[from, to]` matches durations in the range.
Use `default` for an open end. A bound can also be a number instead of a string: epoch seconds for a
`Timestamp`, and a count of seconds for a `Timespan`.

```puppet
$ts  = Timestamp('2016-06-01T00:00:00')
$dur = Timespan({'hours' => 5})

notice($ts =~ Timestamp['2015-01-01', '2017-01-01']) # true
notice($ts =~ Timestamp['2020-01-01', default]) # false
notice($ts =~ Timestamp[1451606400, default]) # true, epoch bound
notice($dur =~ Timespan['01:00:00', '10:00:00']) # true
notice($dur =~ Timespan[0, 36000]) # true (0 to 10h)
```

### Examples

- `Timestamp` --- matches any instant.
- `Timestamp['2015-01-01', '2020-01-01']` --- matches an instant in that range.
- `Timestamp['2020-01-01', default]` --- matches any instant from that date onward.
- `Timespan` --- matches any duration.
- `Timespan['01:00:00', '10:00:00']` --- matches a duration between one and ten hours.

### Related data types

`Timestamp` and `Timespan` are both `Scalar` and part of `RichData`, but they are not `ScalarData` and not
`Data`:

```puppet
$ts = Timestamp('2016-01-01T00:00:00')

notice($ts =~ Scalar)     # true
notice($ts =~ RichData)   # true
notice($ts =~ ScalarData) # false
notice($ts =~ Data)       # false
```

The `Data` type covers only the JSON-compatible types, so a parameter or function that expects `Data` does
not accept a `Timestamp` or `Timespan`. Use `RichData`, or the specific type, when you need to accept one.

You can also use [abstract types][abstract types] to match a value that might be a time. For example,
`Optional[Timestamp]` matches a `Timestamp` or `undef`, and `Variant[Timestamp, Timespan]` matches either.
