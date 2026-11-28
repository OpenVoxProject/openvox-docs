---
layout: default
title: "Designing convenient roles"
---

There are several ways to build roles. Start with granular roles, where a reader sees a whole role in one file, and move away from them only in small,
considered steps when the repetition becomes a burden.

The examples start from this web server role:

```puppet
class role::webserver {
  include profile::base
  include profile::time
  include profile::nginx
}
```

## First approach: Granular roles

Make one role per type of node. Suppose the web servers for your intranet also need single sign-on. With granular roles, they get a role of their own:

```puppet
class role::webserver::intranet {
  include profile::base
  include profile::time
  include profile::nginx
  include profile::sso
}
```

Each role is a plain list of profiles, so one class shows everything on that type of node. The cost is repetition: with many slightly different nodes you
get many nearly identical roles, and it's harder to see how they relate.

## Second approach: Conditional logic

Handle the differences between closely related nodes inside one role:

```puppet
class role::webserver {
  include profile::base
  include profile::time
  include profile::nginx

  if $facts['group'] == 'intranet' {
    include profile::sso
  }
}
```

You have fewer roles to maintain. The risk is readability: it's tempting to add a custom fact for each variation, and a reader must then know what those
facts mean. A role that decides what kind of node it is on is doing the job of node classification, and separate roles assigned in your classification
data are usually clearer.

## Third approach: Nested roles

Let roles include other roles:

```puppet
class role::webserver {
  # Parent role:
  include role::server
  # Unique classes:
  include profile::nginx
}

class role::webserver::intranet {
  # Parent role:
  include role::webserver
  # Unique classes:
  include profile::sso
}
```

Each role includes the parent it most resembles, plus the few classes that set it apart. Here `role::webserver::intranet` gets `role::server` through
`role::webserver`. You have less code to maintain, but a reader must open more files to see what a role contains. One level is manageable. Three or four
are hard to follow.

## Fourth approach: Multiple roles per node

The method assigns [exactly one role to each node](the_roles_and_profiles_method.html#configuring-roles-and-profiles), which works best when a node provides
one primary service. If your nodes often provide several, you can assign several roles instead.

For example, an application normally runs on separate application, database, and web servers, and developers want an all-in-one node for testing. Instead of
writing a `role::our_application::monolithic` class, you assign `role::our_application::app`, `role::our_application::db`, and `role::our_application::web`
to those nodes.

You write fewer roles. But no single role describes the node, so you must cross-reference roles and classification data to understand it. The all-in-one
version is also likely to differ from the normal one in small ways, which complicates the normal roles. A separate role can be simpler overall, despite the
repetition.

## Fifth approach: Super profiles

Profiles can include other profiles, so you can require every profile to include whatever else a complete node needs. For example, `profile::nginx` includes
`profile::time` and `profile::base`, and you assign `profile::nginx` directly to web servers. The roles layer disappears.

The chain of dependencies for a complex service can be clearer this way. But you lose flexibility, because profiles can no longer be combined freely or
swapped for alternate implementations. You also lose the plain list of what a node consists of, and the division between complete systems (roles) and
groupings of technology (profiles). Not every profile makes sense as a whole system, so you need another way to track which ones do. Avoid this approach
unless your whole team is sure that it prefers it.

## Sixth approach: Building roles in your classification data

List the profiles directly in whatever assigns classes to nodes: a `classes` array at a role level of your Hiera hierarchy, or the class list that an
external node classifier (ENC) returns. For example, a `roles/webserver.yaml` data file lists `profile::base`, `profile::time`, and `profile::nginx`, and
does the job of the `role::webserver` class.

> **Important:** With an ENC, don't set profile parameters in the ENC. Keep them in Hiera. An ENC that sets parameters declares the class in the
> resource-like way, which conflicts with profiles including other profiles.

Nodes can be classified without writing Puppet code, which suits teams that work in an ENC's user interface, and a node's data file or ENC entry shows the
full content of its role. The drawbacks:

- A static list has none of the Puppet language's conditional logic.
- You can't test a list in a data file with rspec-puppet as you can a role class, and when `classes` is merged across hierarchy levels, the full list for a
  node is harder to see.
- With an ENC, roles leave the repository that holds your profiles, and no longer follow the same code promotion process.
