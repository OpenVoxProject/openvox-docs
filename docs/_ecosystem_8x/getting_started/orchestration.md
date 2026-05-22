---
layout: default
title: "Orchestration"
---

OpenVox's agent-server model is great for **convergence** (gradually bringing systems into compliance),
but sometimes you need **orchestration** — running commands across your fleet right now, deploying code immediately, or executing complex multi-step workflows.

This guide covers:

* [**OpenBolt**](#openbolt) — Orchestration without relying on the Puppet server
* [**Tasks and Plans**](#tasks-and-plans) — Reusable automation


## OpenBolt

OpenBolt is an **agentless** orchestration tool.
It connects to remote nodes via SSH, WinRM, Choria, or other transport methods and runs commands, scripts, tasks, and plans — without requiring an OpenVox agent on the target.
It can also apply snippets of Puppet code on demand; it will automatically install the OpenVox agent package if needed.
Think of it as the "do it now" complement to Puppet's "keep it this way forever" model.

### Installation

The OpenVox project ships Bolt as `openbolt` from the Vox Pupuli repos.
You can install `openbolt` on a machine with or without the agent or server or any other packages installed.
Typically you'd install it onto your workstation rather than onto a server.
The official [Installing OpenVox](https://voxpupuli.org/openvox/install/) guide has step-by-step instructions for enabling the repo for each supported platform.

### Project Setup

Create a Bolt project:

```console
mkdir myproject && cd myproject
bolt project init myproject
```

This creates:

```text
myproject/
├── bolt-project.yaml      # Project configuration
├── inventory.yaml         # Target definitions
├── Puppetfile             # Module dependencies (managed by OpenBolt, don't edit yourself)
├── plans/                 # Bolt plans
└── tasks/                 # Bolt tasks
```

### Inventory

Targets are all the nodes that you're going to connect to and run orchestration actions on.
Your targets are defined in `inventory.yaml`, and they can be listed one-by-one or in named groups.
For more dynamic inventories, you can also use PQL (the PuppetDB Query Language) to retrieve a list of nodes matching a query directly from OpenVoxDB.

```yaml
---
groups:
  - name: webservers
    targets:
      - uri: web1.example.com
      - uri: web2.example.com
    config:
      ssh:
        user: deploy
        private-key: ~/.ssh/id_ed25519
        host-key-check: false
        run-as: root

  - name: databases
    targets:
      - uri: db1.example.com
      - uri: db2.example.com
    config:
      ssh:
        user: deploy
        run-as: root

  - name: all_servers
    groups:
      - webservers
      - databases

  - name: local
    targets:
      - uri: localhost
    config:
      transport: local
```

### Running Commands

```console
# Run a command on all webservers
bolt command run 'systemctl status httpd' --targets webservers

# Run on specific hosts
bolt command run 'df -h' --targets web1.example.com,db1.example.com

# Run on all servers
bolt command run 'uptime' --targets all_servers

# Using PuppetDB for target discovery
bolt command run 'hostname' \
  --query 'nodes[certname] { facts.os.name = "Rocky" }'

# Limit concurrency (don't overwhelm your network)
bolt command run 'yum update -y openssl' --targets all_servers --concurrency 5
```

### Running Scripts

```console
# Copy a local script to all webservers and run it
bolt script run ./scripts/health_check.sh --targets webservers

# Pass arguments to the script
bolt script run ./scripts/deploy.sh --targets webservers \
  --arguments 'version=2.0 environment=production'
```

### File Operations

```console
# Upload a file to all webservers
bolt file upload ./configs/nginx.conf /etc/nginx/nginx.conf --targets webservers

# Download files from the all_servers (great for log collection)
bolt file download /var/log/messages ./collected_logs/ --targets all_servers
```

### Applying Puppet Code

OpenBolt does not require an agent-server infrastructure to be set up.
It will install the OpenVox agent package when needed to apply code, but does not need that agent to be connected to a server.
In this way, it will work similarly to your first exposure to `puppet apply` in the [Whirlwind Guide](index.html).

```console
# Apply a manifest on specified targets
bolt apply manifest.pp --targets web1.example.com

# Apply inline Puppet code
bolt apply -e 'package { "vim": ensure => installed }' --targets all_servers

# Apply a manifest that uses resources from installed modules
bolt apply --modulepath ./modules manifest.pp --targets webservers
```


## Tasks and Plans

### Tasks

Tasks are **single-action scripts** (Bash, Python, PowerShell, Ruby) with structured metadata that tells OpenBolt how they can be run and what kind of data they'll return.
They're like scripts, but with parameter validation, documentation, and discoverability.

#### Creating a Task

```bash
#!/bin/bash
# tasks/restart_service.sh
# Restart a service and verify it's running

SERVICE=$PT_service_name   # Parameters are passed as environment variables with PT_ prefix

systemctl restart "$SERVICE"
sleep 2

if systemctl is-active --quiet "$SERVICE"; then
    echo "{\"status\": \"success\", \"service\": \"$SERVICE\", \"state\": \"running\"}"
else
    echo "{\"status\": \"failed\", \"service\": \"$SERVICE\", \"state\": \"stopped\"}" >&2
    exit 1
fi
```

```json
// tasks/restart_service.json (metadata)
{
  "description": "Restart a system service and verify it started successfully",
  "parameters": {
    "service_name": {
      "description": "The name of the service to restart",
      "type": "String"
    }
  },
  "input_method": "environment"
}
```

#### Running a Task

```console
bolt task run myproject::restart_service service_name=httpd --targets webservers
```

### Plans

Plans are **multi-step workflows** written in Puppet language or YAML. They can run commands, tasks, other plans, and include logic (conditionals, error handling, etc.).

#### Puppet Language Plan

```puppet
# plans/rolling_deploy.pp
plan myproject::rolling_deploy (
  TargetSpec $targets,
  String     $version,
  Integer    $batch_size = 2,
) {
  # Get the targets
  $all_targets = get_targets($targets)

  # Deploy in batches
  $all_targets.each |$batch| {
    out::message("Deploying version ${version} to batch...")

    # 1. Disable the load balancer
    run_task('myproject::lb_drain', $batch)

    # 2. Deploy the new version
    run_task('myproject::deploy', $batch,
      version => $version
    )

    # 3. Run health checks
    $results = run_task('myproject::health_check', $batch)

    # 4. Fail fast if health checks fail
    $results.each |$result| {
      unless $result['healthy'] {
        fail_plan("Health check failed on ${result.target.name}")
      }
    }

    # 5. Re-enable in load balancer
    run_task('myproject::lb_enable', $batch)

    out::message("Batch complete!")
  }

  return "Deployed version ${version} to ${all_targets.length} targets"
}
```

#### YAML Plan

YAML plans can be simpler to write if you don't need conditionals or other complexity.

```yaml
# plans/update_packages.yaml
---
description: "Update specific packages across fleet"
parameters:
  targets:
    type: TargetSpec
    description: "Targets to update"
  packages:
    type: Array[String]
    description: "Packages to update"

steps:
  - name: check_current
    command: "rpm -qa ${packages.join(' ')}"
    targets: $targets

  - name: update_packages
    command: "yum update -y ${packages.join(' ')}"
    targets: $targets

  - name: verify_update
    command: "rpm -qa ${packages.join(' ')}"
    targets: $targets

return: $verify_update
```

#### Running a Plan

```console
bolt plan run myproject::rolling_deploy \
  targets=webservers version=2.1.0 batch_size=2

bolt plan run myproject::update_packages \
  targets=all_servers packages='["openssl","curl"]'
```


## Orchestration Best Practices

1. **Start small**: Test orchestration commands on one node before running against the fleet
2. **Use `--noop` and `--concurrency`**: Always dry-run first, and limit concurrency to avoid overwhelming your infrastructure
3. **Pin module versions**: In your `Puppetfile`, always pin to specific versions or tags
4. **Use Bolt for ad-hoc work, Puppet for convergence**: They complement each other
5. **Version your plans and tasks**: Treat them like code — they ARE code
6. **Log everything**: r10k deployments, Bolt runs, and plan outputs should all be logged
