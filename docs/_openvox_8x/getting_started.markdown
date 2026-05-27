---
layout: default
title: "Getting started with OpenVox"
---

# Getting started with OpenVox

This guide walks you through the steps to go from a fresh installation to a working
infrastructure managed with Puppet code. By the end you will have an OpenVox Server,
enrolled agents, and a control repository deployed with r10k.

---

**Want to try the full workflow locally first?** See
[Try OpenVox locally with crafty](./getting_started_local.html) for a Docker Compose
environment that mirrors these steps without needing dedicated servers.

---

## Step 1: Install OpenVox Server

Install OpenVox Server on the node that will compile and serve **catalogs** to your
agents. A catalog is the compiled set of resources and configuration that Puppet applies
to a node.

Follow the [OpenVox Server installation guide](/openvox-server/latest/install_from_packages.html)
for full instructions. When complete, the `puppetserver` service should be running and
reachable on port 8140.

---

## Step 2: Install and enroll agents

Install `openvox-agent` on each node you want to manage, then connect it to the server.

1. Review the [pre-install tasks](./install_pre.html) for system requirements and
   network prerequisites.
2. Install the agent:
   - [Linux](./install_linux.html)
   - [Windows](./install_windows.html)
   - [macOS](./install_osx.html)
3. Run a test check-in on the agent. This submits a certificate signing request (CSR)
   to the server — OpenVox uses mutual TLS so both sides must trust each other before
   the server will issue a catalog:

   ```bash
   sudo /opt/puppetlabs/bin/puppet agent --test
   ```

4. Sign the certificate on the server to approve the agent:

   ```bash
   sudo /opt/puppetlabs/bin/puppetserver ca list
   sudo /opt/puppetlabs/bin/puppetserver ca sign --certname <AGENT_CERTNAME>
   ```

---

## Step 3: Set up a control repository

A control repository is a Git repository that holds all your Puppet environments.
Each branch becomes an [environment](./environments_about.html) on the server. r10k reads this repository and
deploys branches to `/etc/puppetlabs/code/environments/`.

### Create the repository

Start by cloning the [puppetlabs/control-repo](https://github.com/puppetlabs/control-repo)
template, which provides a well-structured starting point:

```bash
git clone https://github.com/puppetlabs/control-repo.git
cd control-repo
```

Create a new empty repository on your Git host (GitHub, GitLab, Gitea, or any host your
server can reach), then point the clone at it. Note that OpenVox uses `production` as
the default environment — make sure your repository's default branch is named
`production`, not `main`:

```bash
git remote remove origin
git remote add origin <YOUR_REPO_URL>
git push -u origin production
```

The template's key files are:

- **`Puppetfile`** — lists modules r10k installs into the environment. Add modules from
  the Puppet Forge here as your infrastructure grows.
- **`environment.conf`** — configures the module path to include the `site-modules/`
  directory alongside Forge modules.
- **`site-modules/`** — where your own roles, profiles, and custom modules live.
- **`manifests/site.pp`** — the main manifest, which is the entry point for node
  classification.
- **`data/`** — Hiera data files, pre-configured with a basic hierarchy.

### Install r10k

[r10k](https://github.com/puppetlabs/r10k) is a code deployment tool that reads your
control repository and installs each branch as a Puppet environment, along with any
modules listed in its Puppetfile.

On the OpenVox Server, install r10k using the Ruby runtime that ships with OpenVox:

```bash
sudo /opt/puppetlabs/puppet/bin/gem install r10k
```

---

Once your control repo is deployed and your infrastructure is established, consider
managing r10k with the [`puppet/r10k`](https://forge.puppet.com/modules/puppet/r10k)
Forge module. It installs r10k and manages `r10k.yaml` as Puppet resources, so
changes to your r10k configuration go through the same code review and deployment
workflow as everything else.

---

### Configure r10k

Create the r10k configuration directory and a minimal `r10k.yaml`:

```bash
sudo mkdir -p /etc/puppetlabs/r10k
```

**`/etc/puppetlabs/r10k/r10k.yaml`:**

```yaml
cachedir: '/var/cache/r10k'
sources:
  control:
    remote: 'https://github.com/your-org/control-repo'
    basedir: '/etc/puppetlabs/code/environments'
```

Replace the `remote` value with the URL of your control repository. If the server
needs an SSH key to clone from your Git host, configure that key for the root user
before running r10k.

### Deploy your first environment

Deploy all branches from the control repository:

```bash
sudo /opt/puppetlabs/puppet/bin/r10k deploy environment -v
```

When complete, `/etc/puppetlabs/code/environments/production/` will contain the
files from your repository's `production` branch.

---

## Step 4: Write and apply Puppet code

With a deployed environment you are ready to write Puppet code and apply it to nodes.
To confirm the full loop is working, add a `notify` resource to
`manifests/site.pp` in your control repository:

```puppet
node default {
  notify { 'Hello from OpenVox!':
    message => 'Your first Puppet catalog change is working.',
  }
}
```

Commit and push the change to the `production` branch of your control repository,
redeploy with r10k, then run the agent:

```bash
sudo /opt/puppetlabs/puppet/bin/r10k deploy environment production -v
sudo /opt/puppetlabs/bin/puppet agent --test
```

You should see a `Notice: Your first Puppet catalog change is working.` line in the
output confirming the agent applied the updated catalog.

From here, a few places to go deeper:

- **[Hello world! Quick start guide](./quick_start_helloworld.html)** — write your first
  class and apply it to a node.
- **[Roles and profiles](./the_roles_and_profiles_method.html)** — the recommended pattern
  for structuring code in larger deployments.
- **[Installing modules](./modules_installing.html)** — add community modules from the
  Puppet Forge to your Puppetfile and deploy them with r10k.
- **[Introduction to Hiera](./hiera_intro.html)** — separate your data from your code
  using Hiera.

---

## What's next?

- **Add more environments** — create a new branch in your control repository and run
  `r10k deploy environment -v` to deploy it. Use environments for testing changes
  before promoting to production.
- **Automate r10k deploys** — use the [`r10k::webhook` class](https://forge.puppet.com/modules/puppet/r10k)
  from the `puppet/r10k` module to set up a webhook that triggers `r10k deploy environment` on every push.
- **Expand your node inventory** — install agents on additional nodes and assign
  them classes in `manifests/site.pp` or through [node definitions](./lang_node_definitions.html).
- **Classify nodes at scale** — use an [External Node Classifier](./nodes_external.html)
  to assign classes from an external source instead of maintaining node definitions
  in `manifests/site.pp`.
