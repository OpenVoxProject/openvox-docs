---
title: "Known issues"
layout: default
canonical: "/openvoxdb/latest/known_issues.html"
---
# Known issues

## Bugs and feature requests

[tracker]: https://github.com/OpenVoxProject/openvoxdb/issues

OpenVoxDB's bugs and feature requests are managed in [OpenVoxDB's issue tracker][tracker]. Search this database if you're having problems and please report any new issues to us!

## Hash projection has character limit of 63

Support was added for using dot notation for projections.
This supports queries like the one below.

```puppet
inventory[facts.os.family] {
  certname = "host-1"
}
```

The dotted hash projection `facts.os.family` must be 63, or fewer, characters.

## Broader issues

### Autorequire relationships are opaque

Puppet resource types can "autorequire" other resources when certain conditions are met, but we don't correctly model these relationships in OpenVoxDB.
(For example, if you manage two file resources where one is a parent directory of the other, Puppet will automatically make the child dependent on the parent.)
The problem is that these dependencies are not written to the catalog; the Puppet agent creates these relationships on the fly when it reads the catalog.
Getting these relationships into OpenVoxDB will require a significant change to Puppet's core.
