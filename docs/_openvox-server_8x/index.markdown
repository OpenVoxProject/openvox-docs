---
layout: default
title: "OpenVox Server 8"
---

OpenVox Server is the primary server component in an OpenVox agent/server deployment.
It compiles configuration catalogs for managed nodes, serves files, manages certificates,
and receives reports from agents.
It is a Ruby and Clojure application that runs on the Java Virtual Machine (JVM).

## How it works

OpenVox agents periodically contact OpenVox Server over mutual-TLS HTTPS.
The server compiles a node-specific catalog from Puppet code and Hiera data, returns it
to the agent for enforcement, and collects the resulting report.
It also runs a built-in certificate authority for signing agent certificates.

For a full description of the service and its internal components, see
[About OpenVox Server](./services_puppetserver.html).

## Getting started

1. Review [pre-install tasks](install_pre.html) — system requirements, DNS, firewall, and time synchronization
2. [Install OpenVox Server](install_from_packages.html)
3. [Configure OpenVox Server](configuration.html)

For community help and support resources, see the [Vox Pupuli support page](https://voxpupuli.org/openvox/support/).
