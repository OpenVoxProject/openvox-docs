---
layout: default
title: Setting up VS Code for OpenBolt
---

# Setting up VS Code for OpenBolt

OpenBolt configuration and inventory files, as well as content such as plans and
task metadata, conform to particular specifications. Making your development
environment aware of these specifications gives you real-time validation and
data type checking as you write, speeding up the development cycle and reducing
errors.

## Validating configuration and inventory files with JSON schemas

You can validate OpenBolt's configuration and inventory files using JSON schemas
published with this documentation. Configuring Visual Studio Code (VS Code) to
use OpenBolt's JSON schemas enables VS Code's live IntelliSense feature, which
gives you functionality like code completion and parameter info for available
fields in the files.

OpenBolt offers the following JSON schemas:

| OpenBolt file                                        | JSON schema                                                         |
| ---------------------------------------------------- | ------------------------------------------------------------------- |
| [`bolt-defaults.yaml`](bolt_defaults_reference.html) | [`bolt-defaults.schema.json`](schemas/bolt-defaults.schema.json)   |
| [`bolt-project.yaml`](bolt_project_reference.html)   | [`bolt-project.schema.json`](schemas/bolt-project.schema.json)     |
| [`inventory.yaml`](bolt_inventory_reference.html)    | [`bolt-inventory.schema.json`](schemas/bolt-inventory.schema.json) |
| [YAML plans](writing_yaml_plans.html)                | [`bolt-yaml-plan.schema.json`](schemas/bolt-yaml-plan.schema.json) |

If your settings still point at the `forgeapi.puppet.com` schemas from the Puppet
Bolt documentation, replace them. Those describe Puppet Bolt, so they offer
options OpenBolt has removed, such as the `pcp` transport, and lack ones it has
added, such as the `choria` transport.

### Enabling schemas

To start using the JSON schemas with VS Code, follow these steps:

1. Install the [YAML
   extension](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml).

1. Open the [user or workspace settings
   file](https://code.visualstudio.com/docs/getstarted/settings) and add the
   following JSON:

    ```json
    {
      "yaml.schemas": {
        "https://docs.openvoxproject.org/openbolt/5.x/schemas/bolt-defaults.schema.json": [
          "bolt-defaults.yaml"
        ],
        "https://docs.openvoxproject.org/openbolt/5.x/schemas/bolt-project.schema.json": [
          "bolt-project.yaml"
        ],
        "https://docs.openvoxproject.org/openbolt/5.x/schemas/bolt-inventory.schema.json": [
          "inventory.yaml"
        ],
        "https://docs.openvoxproject.org/openbolt/5.x/schemas/bolt-yaml-plan.schema.json": [
          "plans/**/*.yaml"
        ]
      }
    }
    ```

📖 **Related information**

- [Configuring OpenBolt](configuring_bolt.html)
- [Inventory files](inventory_files.html)
- [VS Code settings
  file](https://code.visualstudio.com/docs/getstarted/settings)
- [VS Code YAML
  extension](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml)

## Developing OpenBolt content with the Puppet VS Code Extension

Puppet offers a VS Code Extension that you can use when developing content for
your OpenBolt project. The Puppet VS Code Extension includes many powerful
features, including validation for task metadata files, live Intellisense for
Puppet plans, validating Puppetfiles, and more.

To install the Puppet VS Code Extension, see [How to start using the Puppet VS
Code Extension](https://puppet-vscode.github.io/docs/getting-started/).

📖 **Related information**

- [Puppet VS Code Extension
  documentation](https://puppet-vscode.github.io/docs/)
- [Puppet VS Code Extension
  features](https://puppet-vscode.github.io/docs/features/)
