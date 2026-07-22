---
layout: default
title: "Impact Analysis of Code Changes"
---

So you've updated some modules and you've run the tests and you're ready to deploy them.
But do you know how big the blast radius might be if something goes wrong?
Do you know how many of your database servers might be restarting in the next 30 minutes?
Maybe you just want to validate that all the predicted changes are expected or that upgrading the OpenVox server won't cause unexpected changes.

Because OpenVox catalogs are a description of expected state, we can get a reasonable approximation of these questions by comparing _before_ and _after_ catalogs to see what changes.
In other words, if we have live catalogs for all our nodes, then we can build new catalogs using the codebase from a pull/merge request and then see which nodes have differences and what those differences are.

## Catalog Diff

The [Catalog Diff](https://github.com/voxpupuli/puppet-catalog_diff) tool can compare catalogs from various sources.
It can retrieve catalogs from different servers, from two different environments on the same server, from OpenVoxDB, or even from files dumped to disk.

The simplest use case is just comparing two catalogs on disk.
Let's generate some as a non-root user to see how it works.
Create the file `~/.puppetlabs/etc/code/environments/production/manifests/site.pp` and the directory structure underneath.
Add a simple notify resource:

```puppet
notify { 'hello': }
```

Then let's generate a catalog and save it to disk.
We'll need to suppress the `Notice` output to get valid JSON.

```console
puppet catalog compile --log_level warning > old.json
```

Update your notify to `notify { 'world': }` and generate a second catalog saved as `new.json`.

Now we can see the difference in the two catalogs.

```console
$ puppet module install puppet-catalog_diff
Notice: Preparing to install into /Users/ben.ford/.puppetlabs/etc/code/environments/production/modules ...
Notice: Downloading from https://forgeapi.puppet.com ...
Notice: Installing -- do not interrupt ...
/Users/ben.ford/.puppetlabs/etc/code/environments/production/modules
└── puppet-catalog_diff (v5.0.0)
$ puppet catalog diff old.json new.json
Notice: Add --debug for realtime output, add --render-as {json,yaml} for parsed output

--------------------------------------------------------------------------------
new                                                           33.33333333333333%
--------------------------------------------------------------------------------
Old version:  1780641948
New version:  1780641933
Old environment:  production
New environment:  production
Total resources in old: 3
Total resources in new: 3
Only in old:
  notify[hello]
Only in new:
  notify[world]
Catalog percentage added:    33.33
Catalog percentage removed:  33.33
Catalog percentage changed:  0.00
Added and removed resources: +1 / -1
Node percentage:  33.33333333333333
Node differences: 2

--------------------------------------------------------------------------------
1 out of 1 nodes changed.                                     33.33333333333333%
--------------------------------------------------------------------------------

Nodes with the most changes by percent changed:
1. new                                                                    33.33%

Nodes with the most changes by differences:
1. new                                                                        2
```

## Diffing production catalogs

Comparing a couple JSON format catalogs dumped to disk can be handy, but the real value comes from comparing live catalogs from real nodes in your infrastructure.

First you'll need to configure OpenVoxDB access for the node running the catalog diff tool by adding its `certname` to `/etc/puppetlabs/puppetdb/certificate-allowlist`.

Then you need to allow the same node access to request catalogs for any nodes.
You'll add the following stanza to `/etc/puppetlabs/puppetserver/conf.d/auth.conf` on all compiler nodes.

```json
{
    match-request: {
        path: "^/puppet/v4/catalog"
        type: regex
        method: [post]
    }
    allow: ["catalog-diff-node-certname"]
    sort-order: 500
    name: "puppetlabs certless catalog"
},
```

Now you can compare catalogs by requesting them directly.

```console
puppet catalog diff \
     puppet5.example.com:8140/production puppet6.example.com:8140/production \
     --old_catalog_from_puppetdb \
     --certless
```

The tool is very powerful and has many more options and configurability.
[Find out more on its project page](https://github.com/voxpupuli/puppet-catalog_diff).

Orchestrating this to run on pull/merge requests or the like is beyond the scope of this quick guide, but a community member
[wrote a couple posts](https://dev.to/camptocamp-ops/diffing-puppet-environments-1fno) on setting this up.

## Graphical visualization of differences

A common use case for catalog diffing is to orchestrate a comparison between `staging` and `production` environments.
Then these diffs are used to preflight a merge-up and be prepared for any production changes before they happen.

It's very useful to have a graphical view that provides a summary of changes, but also lets you browse around to specific nodes or services.
For this we use the [Catalog Diff Viewer](https://github.com/voxpupuli/puppet-catalog-diff-viewer).

![Catalog Diff Viewer screenshot](diff_viewer.png)

You can experiment with the [online demo](http://voxpupuli.org/puppet-catalog-diff-viewer) by selecting the `Demo 1` report from the dropdown menu.
{: .tip }

It's shipped as a container, which means that when you have some report files saved into `data/`, then you can simply run the container and then browse the viewer at [http://localhost:8080/](http://localhost:8080/).

```console
docker run -ti \
 -v ./data:/data \
 -p 8080:8080 \
 ghcr.io/voxpupuli/puppet-catalog-diff-viewer
```

See the project page for more configuration options.
