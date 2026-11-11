---
layout: default
title: Dotted fact names
---

# Dotted fact names {#deprecating-dotted-fact-names}

OpenBolt prints a deprecation warning when a target has a fact whose name
contains a dot, such as `role.name`. The fact can come from the inventory file
or be set during a plan run:

```text
Target 'localhost' includes dotted fact names: 'role.name'. Dotted fact names are deprecated and Bolt does not automatically convert facts with dotted names to structured facts. For more information, see https://pup.pt/bolt-dotted-facts [ID: dotted_fact_name]
```

OpenBolt keeps such a fact under its dotted name. It doesn't turn `role.name`
into a `role` fact that contains `name`. OpenFact does the same by default, but
when its [`force-dot-resolution`](/openfact/latest/configuring_openfact.html)
setting is `true`, it treats the dot as structure. On targets with that setting,
the same name means a structured fact to OpenFact and a flat one to OpenBolt.

To avoid the ambiguity, use structured facts instead of dotted names. For
example, in an inventory file:

```yaml
targets:
  - uri: web01.example.com
    facts:
      role:
        name: server
```

To suppress the warning instead, add the `dotted_fact_name` ID to the
`disable-warnings` option in your project configuration:

```yaml
# bolt-project.yaml
disable-warnings:
  - dotted_fact_name
```
