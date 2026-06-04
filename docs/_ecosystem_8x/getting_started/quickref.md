---
layout: default
title: "Quick Reference"
---

OpenVox has quite a few configuration files and commands and concepts.
Here's a very quick reference to some of the most common things you'll need.
Refer back to the full documentation and references for complete information.

## Quick Reference Card

Here are some of the commands you'll use most often as you're getting started:

| Command | What It Does |
| ------- | ------------ |
| `puppet --version` | Shows the installed version |
| `puppet apply manifest.pp` | Applies a local manifest |
| `puppet apply --noop manifest.pp` | Dry-run (shows what *would* change) |
| `puppet agent -t` | One-time agent run (test mode) |
| `puppet resource user` | Lists all users on the system |
| `puppet resource package httpd` | Shows the state of the `httpd` package |
| `puppet config print all` | Dumps all configuration settings |
| `puppet module list` | Lists installed modules |
| `facter os.name` | Shows the OS name fact |
| `facter --json` | Dumps all facts as JSON |


## Common Configuration files

| Command | What It Does |
| ------- | ------------ |
| [`/etc/puppetlabs/puppet/puppet.conf`](/openvox/latest/config_file_main.html) | The main configuration file |
| [`hiera.yaml`](/openvox/latest/hiera_config_yaml_5.html) | Hiera hierarchy configuration |
| [`/etc/puppetlabs/r10k/r10k.yaml`](https://github.com/puppetlabs/r10k/blob/main/r10k.yaml.example) | Code deployment configuration |
| [`/etc/puppetlabs/puppetserver/conf.d`](/openvox-server/8.x/configuration.html) | OpenVox Server configuration |
| [`environment.conf`](/openvox/latest/config_file_environment.html) | Per environment configuration |


## Glossary

| Term | Definition |
| ---- | ---------- |
| **Agent** | The software running on managed nodes that applies catalogs |
| **Catalog** | A compiled document describing all resources and their desired state |
| **CA** | Certificate Authority — manages SSL certificates for mTLS |
| **Certname** | A node's unique identifier (usually its FQDN) |
| **ENC** | External Node Classifier — assigns classes/parameters to nodes |
| **Environment** | An isolated set of Puppet code (production, staging, etc.) |
| **Fact** | A piece of information about a node (OS, IP, RAM, etc.) |
| **Forge** | The Puppet Forge — community module repository |
| **Hiera** | Hierarchical data lookup system |
| **Idempotent** | Can be applied repeatedly with the same result |
| **Manifest** | A `.pp` file containing Puppet code |
| **Module** | A self-contained bundle of Puppet code |
| **mTLS** | Mutual TLS — both client and server verify each other's certificates |
| **Node** | A managed system (server, VM, container, etc.) |
| **OpenBolt** | OpenVox's name for Bolt; package `openbolt`, binary still `bolt` |
| **OpenFact** | OpenVox's name for Facter; binary still `facter` |
| **OpenVoxDB** | OpenVox's name for PuppetDB; packages `openvoxdb`, `openvoxdb-termini` |
| **PQL** | Puppet Query Language — SQL-like language for querying PuppetDB |
| **Primary Server** | The central PuppetServer that compiles catalogs |
| **Resource** | A single unit of configuration (file, package, service, etc.) |
| **r10k** | Tool for deploying Puppet code from Git |

