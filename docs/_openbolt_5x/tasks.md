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

- [Inspecting tasks](inspecting_tasks.html) — Look up a task's parameters and metadata before you run it.
- [Running tasks](bolt_running_tasks.html) — Run a task from the command line or from a plan.
- [Writing tasks](writing_tasks.html) — Package a task with metadata describing its parameters.
- [Task helpers](task_helpers.html) — Use language-specific libraries to simplify writing tasks.
