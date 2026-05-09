---
layout: default
title: "Architecture & Concepts"
---

> *Understanding how all the pieces fit together — or, "Why are there so many services?"*

## The Big Picture

OpenVox (like Puppet before it) follows a **client-server** architecture with a declarative model.
Instead of writing scripts that say *"do this, then do that"* and then running those scripts on all your nodes,
you describe the **desired state** of your systems on the server and let OpenVox figure out how to get there across the whole infrastructure.

## Core Components

### 🦊 The Puppet Agent (`puppet`)

The agent is the service that runs on **every managed node** (server, workstation, container — anything you want to manage).
Its job is simple but important.
It gathers facts about the system such as the OS, IP address, system architecture, etc.) that are used for catalog compilation.
Then it enforces the catalog and sends a report back to the server.


### 🖥️ PuppetServer (`puppetserver`)

PuppetServer is the **brains of the operation**.
It will use the facts gathered by the agent to compile a catalog specifically tailored to that node.
Then it will forward the run report to OpenVoxDB.

The CA subsystem of the server will also issue and manage certificates for the whole infrastructure.


### 📊 OpenVoxDB

OpenVoxDB is the **data warehouse** for your infrastructure. Every time an agent runs, it stores:

* **Facts** — What each node looks like (OS, hardware, network, custom facts)
* **Catalogs** — The definition of how each node *should* be configured
* **Reports** — What happened during each OpenVox run


## The Agent Run: Step by Step

Here's what happens during a typical agent run, from start to finish:

```text
Agent Node                                    Primary Server Node
──────────                                    ───────────────────
1. Agent wakes up (timer or manual)
   │
2. Facter gathers system facts
   │
3. Agent sends facts ──────────────────────►  4. Server receives facts
                                              │
                                              5. Server compiles catalog
                                              │  (code + facts + Hiera data)
                                              │
4. Agent receives catalog ◄────────────────── 6. Server sends catalog
   │
5. Agent compares catalog to
   current system state
   │
6. Agent applies changes
   (creates files, installs packages,
    starts services, etc.)
   │
7. Agent sends report ────────────────────►   8. Server stores report
                                                 in PuppetDB
```

When the agent finishes, it returns an exit code:

| Exit Code | Meaning |
| --------- | ------- |
| `0` | No changes needed — system already matches desired state |
| `1` | Errors occurred during the run |
| `2` | Changes were successfully applied |
| `4` | Failures occurred (some resources failed) |
| `6` | Both changes and failures occurred |

{% include alert.html type="warning" title="Common gotcha" content="Exit code **2** means 'changes applied successfully.'
It's NOT an error! Many CI/CD systems treat non-zero exit codes as failures, so you may need to handle this explicitly.
Puppet has been confusing automation engineers with this since approximately forever." %}

## Other Interesting Components

You'll also want at least a passing familiarity with these components.

### 📋 Facter

Facter is a **cross-platform system profiling tool**. It discovers facts about the node — things like:

* Operating system and version
* IP addresses and MAC addresses
* CPU count, architecture, and model
* Memory and disk information
* Cloud provider metadata (AWS, GCP, Azure)
* Virtualization status

Facts are available in your Puppet code as variables (e.g., `$facts['os']['name']`), which lets you easily write conditional logic like "install `apache` on RedHat, install `apache2` on Debian."


### 📚 Hiera

Hiera is the **hierarchical data lookup system** built into Puppet.
It lets you separate your **data** (parameters, configuration values) from your **code** (classes, modules).
Instead of hardcoding values in your manifests, you put them in YAML files organized in a hierarchy and the server will resolve them to the desired specificity during catalog compilation.

Hiera typically searches from most-specific to least-specific, returning the first match.
This means you can set defaults in `common.yaml` and override them per-node, per-OS, or per-environment.


### 🤖 r10k

R10k is the codebase deploying robot.
It will read the `Puppetfile` from your git *control repo* and use that to build the Puppet codebase on your OpenVox server.
This drastically reduces the amount of maintenance churn you need to do to just maintaining a list of the modules you want installed.

{% include alert.html type="tip" title="Fun fact" content="Robot9000 was an IRC moderation script designed to reduce certain kinds of trolling in the *xkcd* chat rooms. R10k was 'one better'." %}


## Environments

Environments are directories on the server that let you **isolate different versions of your Puppet code**.
This makes it easy to test updates to your codebase before deploying them to your whole infrastructure.
OpenVox ships with a single default environment: **`production`** and anything else is up to your choice.
There's no standard set of environments; you create whatever makes sense for your organization.

When using **r10k** for code deployment (which most teams do), environments map **directly to Git branches** in your control repository.
Create a branch, deploy with r10k, and a matching environment appears on the server.
Delete the branch and it disappears from the server.
This means your environments are as dynamic as your Git workflow; you can create an environment on the fly to test a new feature and then dispose of it when done.

## Next Steps

* Learn a bit more about the [Puppet Language](language.html) and classifying nodes.
* See how to [orchestrate](orchestration.html) one-off tasks.
