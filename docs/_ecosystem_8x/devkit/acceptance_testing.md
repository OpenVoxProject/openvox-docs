---
layout: default
title: "Acceptance Testing with Beaker"
---

Unit testing and knowing that all the individual bits compile the way we expect to is critical, especially for preventing regressions as we continue maintenance on a module.
But nothing compares to knowing what the module actually _does_ when you enforce it on a node.

For example, knowing that a class includes a `package` resource with the expected package name is one thing.
But that doesn't help if the OS changes the name of the package in newer releases.

Vox Pupuli uses an acceptance test framework known a Beaker.
It will deploy various infrastructure configurations using various hypervisors, defaulting to Docker.
In other words, it will deploy a server and one or more agent nodes and then validate that the module classes actually do what they claim when they're enforced.

Please see [voxpupuli-acceptance](https://github.com/voxpupuli/voxpupuli-acceptance) for information on how to set up and use this framework.
