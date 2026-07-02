---
layout: default
title: Orchestrating workflows with plans
---

# Orchestrating workflows with plans

Plans are sets of tasks that can be combined with other logic. This allows you
to do complex task operations, such as running multiple tasks with one command,
computing values for the input for a task, or running certain tasks based on
results of another task. You write plans in the Puppet language. And like tasks,
plans are packaged in modules and can be shared on the Forge.

- [Inspecting plans](inspecting_plans.html) — Determine what effect a plan has on your targets before you run it.
- [Running plans](bolt_running_plans.html) — Run a plan from the command line or from another plan.
- [Writing plans in YAML](writing_yaml_plans.html) — Define simple workflows as a list of steps.
- [Writing plans in the Puppet language](writing_plans.html) — Write plans with the full expressiveness of the Puppet language.
- [Debugging plans](debugging_plans.html) — Print the result of each plan step to standard output.
- [Testing plans](testing_plans.html) — Write unit tests for plans with BoltSpec.
