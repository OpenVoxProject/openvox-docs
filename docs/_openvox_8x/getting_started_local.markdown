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
- A fork of [puppetlabs/control-repo](https://github.com/puppetlabs/control-repo) on
  your Git host. Open the repository on GitHub and click **Fork** to create a copy
  under your own account. You will point the server at your fork so you can push
  changes and see them applied in Step 4.

Clone crafty and change into the OSS example directory:

```bash
git clone https://github.com/voxpupuli/crafty
cd crafty/openvox/oss
```

---

## Step 1: Start the OpenVox Server

The server container runs r10k automatically on startup, so configure your control
repository before bringing it up. Open `compose.yaml`, find the commented-out
`R10K_REMOTE` line, uncomment it, and update it to point at your fork:

```yaml
R10K_REMOTE: https://github.com/<YOUR_ORG>/control-repo.git
```

Then start the stack. The server takes a minute to become healthy as it bootstraps
its CA and runs r10k — start it now and continue reading while it initialises:

```bash
docker compose --profile openvox up -d
```

Check readiness at any point with:

```bash
docker compose ps
```

---

## Step 2: Install and enroll agents

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
Notice: Applied catalog in 0.01 seconds
```

---

## Step 3: Verify your control repository

The server runs r10k during startup and deploys each branch of your control repository
as a Puppet environment. Verify the `production` environment was deployed:

```bash
docker exec oss-openvoxserver-1 ls /etc/puppetlabs/code/environments/
```

The container is named `oss-openvoxserver-1` by default; adjust if yours differs.
You should see a `production/` directory containing the files from your fork's
`production` branch.

---

## Step 4: Write and apply Puppet code

The agent run in Step 2 already compiled and applied a catalog from the `production`
environment. To iterate on your Puppet code:

1. Push a change to the `production` branch of your fork. For example, add a `notify`
   resource to `manifests/site.pp`:

   ```puppet
   node default {
     notify { 'Hello from OpenVox!':
       message => 'Your first Puppet catalog change is working.',
     }
   }
   ```

2. Trigger r10k to redeploy:

   ```bash
   docker exec oss-openvoxserver-1 r10k deploy environment production -v
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
