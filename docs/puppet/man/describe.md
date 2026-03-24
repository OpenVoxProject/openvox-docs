---
title: "Man Page: puppet describe"
---

## NAME

`puppet-describe` — Display help about resource types

## SYNOPSIS

Prints help about Puppet resource types, providers, and metaparameters.

## USAGE

puppet describe [-h|--help] [-s|--short] [-p|--providers] [-l|--list] [-m|--meta]

## OPTIONS

**--help**
:   Print this help text
**--providers**
:   Describe providers in detail for each type
**--list**
:   List all types
**--meta**
:   List all metaparameters
**--short**
:   List only parameters without detail

## EXAMPLE

```
$ puppet describe --list
$ puppet describe file --providers
$ puppet describe user -s -m
```

## AUTHOR

David Lutterkort

## COPYRIGHT

Copyright (c) 2011 Puppet Inc., LLC Licensed under the Apache 2.0 License
