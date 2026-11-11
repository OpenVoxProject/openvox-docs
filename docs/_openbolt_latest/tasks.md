---
layout: default
title: Making on-demand changes with tasks
---

# Making on-demand changes with tasks

Tasks are single actions that you run on target machines in your infrastructure.
You use tasks to make as-needed changes to remote systems.

You can write tasks in any programming language that can run on the targets,
such as Bash, Python, or Ruby. Tasks are packaged within modules, so you can
reuse, download, and share tasks on the Forge. Task metadata describes the task,
validates input, and controls how the task runner executes the task.

## How a task works

A task is an executable file in a module's `tasks/` directory, with an optional
metadata file of the same name and a `.json` extension. When you run a task,
OpenBolt copies the executable to each target and runs it there. Parameters
reach the task as environment variables, as JSON on standard input, or as
PowerShell parameters, depending on the `input_method` in the metadata.
Whatever the task writes to standard output becomes its result, and JSON output
is parsed into a structured result you can use in plans.

The task name is the module name followed by the file name without its
extension: `mysql/tasks/sql.rb` is run as `mysql::sql`. A task file named
`init` takes the module's name, so `service/tasks/init.rb` is run as `service`.

## Where tasks come from

- Modules installed in your project from the Forge or from git. Many modules
  ship tasks alongside their classes.
- Modules bundled with OpenBolt, such as `facts`, `package`, `service`, and
  `reboot`. See [Packaged modules](packaged_modules.html) for the full list.
- Your own modules in the project's `modules/` directory.

## In this section

- [Inspecting tasks](inspecting_tasks.html): list the tasks in your project
  and show a task's parameters with `bolt task show`.
- [Running tasks](bolt_running_tasks.html): run a task with `bolt task run` or
  `Invoke-BoltTask` and pass it parameters.
- [Writing tasks](writing_tasks.html): executables, metadata, parameters, and
  cross-platform tasks.
- [Task helpers](task_helpers.html): libraries for Bash, PowerShell, Python,
  and Ruby that parse parameters and report errors in the format OpenBolt
  expects.

Related: [Orchestrating workflows with plans](plans.html) for combining tasks
with logic, and [Module structure](module_structure.html) for where task files
go in a module.
