---
layout: default
title: "Overview of the Vox Pupuli Developer Tooling Kit"
---

Vox Pupuli maintains the standard canonical developer tooling suite for Puppet content.
Nearly every module in the ecosystem is written using our frameworks.
This means that whether you download a module from the Forge, build it with the PDK, or just roll your own that it probably uses Vox Pupuli tooling for testing and validation.

This suite is not currently packaged into a single download.
Instead, you use a scaffolding tool to add references to your module's metadata files and the components are dynamically pulled in as needed.
This style of operation allows your local testing to run exactly the same as it would on CI pipelines from GitHub, Forgejo, Gitlab, or others.

This does expose you more directly to the Ruby ecosystem than you might be used to, but we've done our best to make that as painless as possible.

If you're already familiar with maintaining Puppet content and testing and you just want to know how to migrate away from the PDK, you can
[skip directly to that guide](migrating.html).
{: .tip }

## Who Is This For?

- 🖥️ **System administrators** validating code before you deploy it
- ⚙️ **DevOps engineers** building infrastructure-as-code pipelines
- 🛠️ **Puppet content authors** building or maintaining Puppet modules
