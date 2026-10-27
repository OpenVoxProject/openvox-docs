---
layout: default
title: Orchestrating workflows with plans
---

# Orchestrating workflows with plans

Plans are sets of tasks that can be combined with other logic. This allows you
to do complex task operations, such as running multiple tasks with one command,
computing values for the input for a task, or running certain tasks based on
results of another task. You write plans in the Puppet language or in YAML.
Like tasks, plans are packaged in modules and can be shared on the Forge.

## What a plan can do

A plan runs on the machine where you run OpenBolt and coordinates work on your
targets. From a plan you can run tasks, commands, scripts, and other plans,
upload files, apply blocks of Puppet code, and make decisions based on the
results. Plans take parameters, so one plan can serve several environments.

## Puppet language or YAML

- Puppet language plans (`.pp` files) give you the full language: typed
  parameters, conditionals, iteration, error handling, and `apply` blocks for
  Puppet code.
- YAML plans (`.yaml` files) are a list of steps that run in order. They are
  easier to start with, and steps can embed Puppet expressions where you need a
  little logic. When a YAML plan outgrows that, `bolt plan convert` turns it
  into a Puppet language plan.

## Where plans live

A plan is a file in a module's `plans/` directory. OpenBolt loads plans from your
own modules in the project's `modules/` directory and from the modules it
installs into `.modules/`. The plan name is the module name followed by the
file name, so `modules/my_module/plans/my_plan.pp` is run as
`my_module::my_plan`.

## In this section

- [Inspecting plans](inspecting_plans.html): list the plans in your project
  and show a plan's parameters with `bolt plan show`.
- [Running plans](bolt_running_plans.html): run a plan with `bolt plan run` or
  `Invoke-BoltPlan` and pass it parameters.
- [Writing plans in YAML](writing_yaml_plans.html): the step-based format.
- [Writing plans in the Puppet language](writing_plans.html): control flow,
  functions, targets, and results.
- [Debugging plans](debugging_plans.html): find out why a plan did not do what
  you expected.
- [Testing plans](testing_plans.html): unit tests with BoltSpec.

Related: [Wrapping a script in a plan](creating_a_script_plan.html),
[Applying Puppet code](applying_manifest_blocks.html), and the
[plan functions reference](plan_functions.html).
