---
layout: default
title: "Environment Isolation"
description: "Generating metadata to isolate resources in environments in OpenVox"
---

## Environment isolation

Environment isolation prevents resource types from leaking between your various environments.

If you use multiple environments with OpenVox, you might encounter issues with multiple versions of the same
resource type leaking between your various environments on the server. This doesn't happen with OpenVox's
built-in resource types, but it can happen with any other resource types.

This problem occurs because Ruby resource type bindings are global in the Ruby runtime. The first loaded
version of a Ruby resource type takes priority, and subsequent requests to compile in other environments get
that first-loaded version. Environment isolation solves this issue by generating and using metadata that
describes the resource type implementation, instead of using the Ruby resource type implementation, when
compiling catalogs.

> **Note:** Other environment isolation problems, such as external helper logic issues or varying versions of
> required gems, are not solved by the generated metadata approach. This fixes only resource type leaking.
> Resource type leaking is a problem that affects only servers, not agents.

## Enable environment isolation

To use environment isolation, generate metadata files that OpenVox can use instead of the default Ruby
resource type implementations.

1. On the command line, run `puppet generate types --environment <ENV_NAME>` for each of your environments.
   For example, to generate metadata for your production environment, run:

   ``` bash
   puppet generate types --environment production
   ```

2. Whenever you deploy a new version of OpenVox, overwrite previously generated metadata by running:

   ``` bash
   puppet generate types --environment <ENV_NAME> --force
   ```

## Enable environment isolation with r10k

To use environment isolation with r10k, generate types for each environment every time r10k deploys new code.

1. Use one of the following methods:
   * Modify your existing r10k hook to run the `generate types` command after code deployment.
   * Create a script that first runs r10k for an environment, then runs `generate types` as a post-run
     command.
2. If you have enabled environment-level purging in r10k, whitelist the `resource_types` folder so that
   r10k doesn't purge it.

## Troubleshooting environment isolation

If the `generate types` command cannot generate certain types, if the generated type has missing or
inaccurate information, or if generation itself has errors or fails, you will get a catalog compilation error
of "type not found" or "attribute not found."

To fix these errors:

1. Ensure that your OpenVox resource types are correctly implemented. Refactor any problem resource types.
2. Regenerate the metadata by removing the environment's `.resource_types` directory and running
   `generate types` again.
3. If you continue to get catalog compilation errors, disable environment isolation to help isolate the error.

To disable environment isolation:

1. Remove the `generate types` command from any r10k hooks.
2. Remove the `.resource_types` directory.

## The `generate types` command

When you run `puppet generate types`, it scans the entire environment for resource type implementations,
excluding core OpenVox resource types.

The command accepts the following options:

Option                     | Description
---------------------------|------------
`--environment <ENV_NAME>` | The environment for which to generate metadata. Defaults to `production`.
`--force`                  | Overwrite all previously generated metadata.

For each resource type implementation it finds, the command generates a corresponding metadata file in the
`<env-root>/.resource_types` directory. It also syncs the directory so that:

* Types removed from modules are removed from `resource_types`.
* Types added to modules are added to `resource_types`.
* Types that have not changed (based on timestamp) are kept as-is.
* Types that have changed (based on timestamp) are overwritten with freshly generated metadata.

The generated metadata files have a `.pp` extension and are read-only. Do not delete them, modify them, or
use expressions from them in manifests.
