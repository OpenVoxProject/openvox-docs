---
layout: default
title: "Interactive Hiera Demo"
---
<!-- markdownlint-disable-file MD055 MD056 -->

This page renders Hiera configuration and data in a graphical and interactive table.
It will help you understand how data is resolved and how changing parameters alters the resolution.

## The `hiera.yaml` config file

This Hiera config file is located in the root of a Puppet environment `hiera.yaml`.
It describes a hierarchy relative to that environment's `datadir`.
Path names are resolved using *facts* and other variables.

 ```yaml
 # <ENVIRONMENT>/hiera.yaml
 ---
 version: 5

 hierarchy:
   - name: "Per-node data"                   # Human-readable name.
     path: "nodes/%{trusted.certname}.yaml"  # File path, relative to datadir.
                                    # ^^^ IMPORTANT: include the file extension!

   - name: "Per-OS defaults"
     path: "os/%{facts.os.family}.yaml"

   - name: "Common data"
     path: "common.yaml"
 ```

This file describes a hierarchy of directories and yaml files matching the resolved paths from the hierarchy.

```console
[/etc/puppetlabs/code/environments/production]$ tree data
├── common.yaml
├── nodes
│   ├── node1.example.com.yaml
│   └── node2.example.com.yaml
└── os
    ├── debian.yaml
    ├── redhat.yaml
    └── Windows.yaml
```

## Resolving data

Each of the files in the hierarchy may contain keys and values.
When Hiera resolves keys, it will inspect these files in the order described.
The first value found wins.

### [Demo] Understand how changes in a single fact change the resolution

The table below represents the values that will be resolved when a catalog is compiled for `node1.example.com` on various platforms.
The layers of the hierarchy are represented by rows, and each item being resolved is a column.
Resolve each key by starting at the header and reading straight down the column until you find a value.
Use the tabs to resolve it as if `node1` were various supported platforms.
Notice the resolved path of each layer for the different platforms.

{% tabs platform %}

  {% tab platform RedHat %}

| Layer                               | `webserver` | `threads` | `backup`   | `cluster`    |
|-------------------------------------|-------------|-----------|------------|--------------|
| `data/nodes/node1.example.com.yaml` |             |           |            | >>`denver`<< |
| `data/os/redhat.yaml`               | >>`httpd`<< | >>6<<     |            |              |
| `common.yaml`                       | `apache`    | 4         | >>`true`<< | `laramie`    |
| Resolved Values:                    | `httpd`     | 6         | `true`     | `denver`     |
{:class="resolution"}

  {% endtab %}

  {% tab platform Ubuntu %}

| Layer                               | `webserver`   | `threads` | `backup`   | `cluster`    |
|-------------------------------------|---------------|-----------|------------|--------------|
| `data/nodes/node1.example.com.yaml` |               |           |            | >>`denver`<< |
| `data/os/debian.yaml`               | >>`apache2`<< |           |            |              |
| `common.yaml`                       | `apache`      | >>4<<     | >>`true`<< | `laramie`    |
| Resolved Values:                    | `apache2`     | 4         | `true`     | `denver`     |
{:class="resolution"}

  {% endtab %}

  {% tab platform Debian %}

| Layer                               | `webserver`   | `threads` | `backup`   | `cluster`    |
|-------------------------------------|---------------|-----------|------------|--------------|
| `data/nodes/node1.example.com.yaml` |               |           |            | >>`denver`<< |
| `data/os/debian.yaml`               | >>`apache2`<< |           |            |              |
| `common.yaml`                       | `apache`      | >>4<<     | >>`true`<< | `laramie`    |
| Resolved Values:                    | `apache2`     | 4         | `true`     | `denver`     |
{:class="resolution"}

  {% endtab %}

  {% tab platform Windows %}

| Layer                               | `webserver`        | `threads` | `backup`    | `cluster`    |
|-------------------------------------|--------------------|-----------|-------------|--------------|
| `data/nodes/node1.example.com.yaml` |                    |           |             | >>`denver`<< |
| `data/os/Windows.yaml`              | >>`iis`<<          | >>1<<     | >>`false`<< |              |
| `common.yaml`                       | `apache`           | 4         | `true`      | `laramie`    |
| Resolved Values:                    | `iis`              | 1         | `false`     | `denver`     |
{:class="resolution"}

  {% endtab %}

{% endtabs %}

Notice that the only layer changing and affecting the resolved values is `os/%{facts.os.family}.yaml`.
This is because the only *fact* we are changing is `os.family`.
Also note that Ubuntu and Debian resolve exactly the same; because they're both `debian` family, they both resolve to the exact same file.
{: .tip }


### [Demo] Understand how simultaneous changes in multiple facts change the resolution

This table should be read just like the one above.
It represents the values resolved when compiling the same catalog for two different nodes.
`node1.example.com` is a RedHat 9 machine and `node2.example.com` is a Debian 12 machine.

As you might expect, `node1.example.com` resolves exactly as it did above, but `node2.example.com` has a node specific overlay overriding some values.
This means that multiple layers are being resolved to a different path as you switch tabs.

{% tabs nodes %}

{% tab nodes node1.example.com %}

| Layer                               | `webserver` | `threads` | `backup`   | `cluster`    |
|-------------------------------------|-------------|-----------|------------|--------------|
| `data/nodes/node1.example.com.yaml` |             |           |            | >>`denver`<< |
| `data/os/redhat.yaml`               | >>`httpd`<< | >>6<<     |            |              |
| `common.yaml`                       | `apache`    | 4         | >>`true`<< | `laramie`    |
| Resolved Values:                    | `httpd`     | 6         | `true`     | `denver`     |
{:class="resolution"}

{% endtab %}

{% tab nodes node2.example.com %}

| Layer                               | `webserver`   | `threads` | `backup`   | `cluster`     |
|-------------------------------------|---------------|-----------|------------|---------------|
| `data/nodes/node2.example.com.yaml` | >>`nginx`<<   | >>8<<     |            |               |
| `data/os/debian.yaml`               | `apache2`     |           |            |               |
| `common.yaml`                       | `apache`      | 4         | >>`true`<< | >>`laramie`<< |
| Resolved Values:                    | `nginx`       | 8         | `true`     | `laramie`     |
{:class="resolution"}

{% endtab %}

{% endtabs %}

Notice that only the most specific value for each key is resolved.
Hiera has other more complex ways of defining layers and hierarchies, but they all follow this pattern.
{: .tip }
