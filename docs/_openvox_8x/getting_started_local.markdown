---
layout: default
title: "Try OpenVox locally with crafty (experimental)"
---

# Try OpenVox locally with crafty (experimental)

Before setting up production infrastructure you can run the full OpenVox stack —
server, OpenVoxDB, an agent, and r10k — locally using Docker Compose via
[voxpupuli/crafty](https://github.com/voxpupuli/crafty). This mirrors the steps in the
[Getting started guide](./getting_started.html) and is a fast way to get familiar with
the workflow before committing to a real installation.

## Prerequisites

- Docker and Docker Compose installed and running.
- Your own copy of
  [OpenVoxProject/control-repo-template](https://github.com/OpenVoxProject/control-repo-template)
  on your Git host. Open the template on GitHub and click **Use this template** to
  create a copy under your own account. You will point the server at your copy so
  you can push changes and see them applied in Step 4.

Clone crafty and change into the OSS example directory:

```bash
git clone https://github.com/voxpupuli/crafty
cd crafty/openvox/oss
```

---

## Step 1: Deploy your control repository

The `oss` example shares its code directory (`./openvox-code`) between the server
container and the [r10k container image](https://github.com/voxpupuli/container-r10k).
Run r10k once before starting the server, so the code directory is populated (with
the right ownership) by the time the server boots. Each branch of your control
repository is deployed as a Puppet [environment](./environments_about.html):

```bash
docker run --rm \
  -e PUPPET_CONTROL_REPO=https://github.com/<YOUR_ORG>/<YOUR_REPO>.git \
  -v "$PWD/openvox-code:/etc/puppetlabs/code" \
  ghcr.io/voxpupuli/r10k:latest deploy environment -mv
```

Verify the `production` environment was deployed:

```bash
ls ./openvox-code/environments/production
```

You should see the files from your copy's `production` branch.

> **Note:** The commented-out `R10K_REMOTE` variable in `compose.yaml` is not used
> by the current server image — the r10k container above does the deployment.

---

## Step 2: Start the OpenVox Server

Start the stack. The server takes a minute to become healthy as it bootstraps its
CA — start it now and continue reading while it initialises:

```bash
docker compose --profile openvox up -d
```

Check readiness at any point with:

```bash
docker compose ps
```

---

## Step 3: Install and enroll agents

Once all containers report healthy, run the agent container. crafty enables
[autosigning](./ssl_autosign.html), so the certificate is approved automatically —
no manual signing step is needed:

```bash
docker compose --profile test run --remove-orphans testing agent -t
```

The agent connects to the server, has its certificate signed, and applies the catalog
compiled from your control repository. A successful run ends with output like:

```text
Notice: Catalog compiled by puppet
Info: Applying configuration version 'puppet-production-<commit>'
Notice: Applied catalog in 0.01 seconds
```

The configuration version comes from the control repository's `config_version`
script and names the deployed environment and Git commit.

---

## Step 4: Write and apply Puppet code

The agent run in Step 3 already compiled and applied a catalog from the `production`
environment. To iterate on your Puppet code:

1. Push a change to the `production` branch of your copy. For example, add a `notify`
   resource to `manifests/site.pp`:

   ```puppet
   node default {
     notify { 'Hello from OpenVox!':
       message => 'Your first Puppet catalog change is working.',
     }
   }
   ```

2. Run the r10k container again to redeploy:

   ```bash
   docker run --rm \
     -e PUPPET_CONTROL_REPO=https://github.com/<YOUR_ORG>/<YOUR_REPO>.git \
     -v "$PWD/openvox-code:/etc/puppetlabs/code" \
     ghcr.io/voxpupuli/r10k:latest deploy environment -mv
   ```

3. Run the agent again to apply the updated catalog:

   ```bash
   docker compose --profile test run --remove-orphans testing agent -t
   ```

---

## Tear down

```bash
./clean.sh
```

This removes all containers and volumes, giving you a clean slate for the next run.

---

## Next steps

Once you are comfortable with the workflow, follow the
[Getting started guide](./getting_started.html) to set up a production installation
with real servers and agents.
