---
layout: default
title: Inspecting plans
---

# Inspecting plans

Before you run a plan in your environment, inspect the plan to determine what
effect it has on your targets.

> 🔩 **Tip:** Bolt is packaged with a collection of modules that contain useful
> plans to support common workflows. For details, see [Packaged
> modules](packaged_modules.html).

## Discover plans

View a list of available plans:

- _\*nix shell command_

  ```shell
  bolt plan show
  ```

- _PowerShell cmdlet_

  ```powershell
  Get-BoltPlan
  ```

If you don't see a plan you were expecting to find, make sure the plan is
located in the correct directory. For more information, see [How Bolt locates
plans](./bolt_running_plans.html#plan-location)

## Show documentation for a plan

Use the following command to view parameters and other details for a plan,
including whether a plan supports `noop`:

- _\*nix shell command_

  ```shell
  bolt plan show <PLAN NAME>
  ```

- _PowerShell cmdlet_

  ```powershell
  Get-BoltPlan -Name <PLAN NAME>
  ```
