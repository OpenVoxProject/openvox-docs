---
layout: default
title: "Setting Up an OpenVox Server"
---

Using `puppet apply` is great for standalone work, but the real power of OpenVox comes from the agent-server architecture, where one or more OpenVox servers compile catalogs for all your nodes.
If you'd like to try it out, then we'll set up a server and connect our agent.

**What you'll learn:**

* [Setting up an OpenVox Server](#server-installation)
* [Managing something with your new server](#managing-something-with-your-new-server)
* [Where to go next](#next-steps)


## Prerequisites

Before we dive in, you'll need:

* The machine you already set up with the OpenVox agent
* A Linux machine for the OpenVox server
* Root or `sudo` access
* Internet connectivity (to reach the package repos)
* A healthy sense of adventure

The OpenVox server currently supports only Linux platforms rather than everything that the agent runs on.
{: .tip }

## Server Installation

We're going to use two nodes for this testing infrastructure; the agent you already built and a server node.
It's possible to run both on the same node (and most server nodes do indeed also run the agent to self-manage), but doing so makes it easy to slip up and accidentally write code that requires local filesystem access.

Read carefully to see which node the instructions are meant to run on; we'll switch back and forth a few times.

### *[Server Node]* Installation

Install the server on a Linux machine following the [installation guide](/openvox-server/latest/install_from_packages.html).
This will require you to install a supported JDK, and configure or validate firewall and network settings.
Make sure to complete all the pre-install tasks **prior to installation**; it can be fiddly to recover an in-progress failed install.


### *[Agent Node]* Connecting the Agent

You already have an agent installed.
Now let's configure it to connect to the server.

```console
sudo puppet config set server your-openvox-server.example.com --section agent
```

Now we'll generate and sign certificates so that your nodes can communicate securely.
Depending on what you've experimented with, you may have already unknowingly created certificates, so we'll just reset the whole SSL directory to start fresh.
In regular operation, you'll rarely need to do this.

```console
sudo rm -rf /opt/puppetlabs/puppet/ssl
```

Now we'll run the agent once to generate and request a certificate:

```console
sudo puppet agent -t
```

You'll see something like this.
If you don't see the certificate generation then go back to the previous step to reset the SSL directory and try again.
The name printed in this output is known as the `certname` and is the infrastructure-wide identifier for this node.
By default, it's the same as your hostname.

```console
$ sudo puppet agent -t
Info: Creating a new RSA SSL key for agent1.example.com
Info: csr_attributes file loading from /etc/puppetlabs/puppet/csr_attributes.yaml
Info: Creating a new SSL certificate request for agent1.example.com
Info: Certificate Request fingerprint (SHA256): AB:CD:12:34:...
Exiting; no certificate found and waitforcert is disabled
```

### *[Server Node]* Sign the Certificate

See the outstanding certificate signing requests:

```console
sudo puppetserver ca list
```

Sign the agent's certificate, using the same name as shown in the list:

```console
sudo puppetserver ca sign --certname agent1.example.com
```

Or sign all pending requests:

```console
sudo puppetserver ca sign --all
```

### *[Agent Node]* Install the Certificate

Run the agent again to download and install the freshly signed certificates:

```console
$ sudo puppet agent -t
Info: Refreshing CA certificate
Info: CA certificate is unmodified, using existing CA certificate
Info: Refreshing CRL
Info: CRL is unmodified, using existing CRL
Info: Using environment 'production'
Info: Retrieving pluginfacts
Info: Retrieving plugin
Info: Loading facts
Notice: Requesting catalog from puppet.example.com:8140 (192.168.1.100)
Notice: Catalog compiled by puppet.example.com
Info: Applying configuration version 'openvox-production-719ab13e0a1'
Notice: Applied catalog in 2.55 seconds
```

The `-t` flag (short for `--test`) runs the agent in test mode with verbose output and detailed reporting.
For production runs, the agent daemon (managed by systemd) runs automatically every 30 minutes.
Use `puppet agent -t --noop` for a dry-run that shows what *would* change without actually changing anything.
This is invaluable for CI/CD pipelines and change reviews.
{: .tip }

This time it should successfully connect, download its (empty) catalog, and apply it.
You're in business!


## Managing Something With Your New Server

You've now got a fully functional OpenVox server managing an infrastructure made up of a single agent.
It's not yet really doing much though, since you haven't defined any configuration for your infrastructure.
Let's write some!

### *[Server Node]* Create a main site manifest

The OpenVox server always starts compiling with a single starting point, no matter which node it is compiling for.
This is called the *main manifest* or *site manifest* and you can read about [more advanced usage](/openvox/latest/dirs_manifest.html) in the docs.

Let's create a site manifest that will ensure that all nodes are enforcing configuration regularly.
We'll also add a bit of configuration for specific nodes.

Edit the file `/etc/puppetlabs/code/environments/production/manifests/site.pp`, creating it and any directory structure as needed.

```puppet
# global configuration that applies unconditionally to all nodes
service { 'puppet':
  ensure => running,  # ensure it's currently running
  enable => true,     # and will start at system bootup
}

node 'agent1.example.com' {
  file { '/tmp/hello-openvox.txt':
    ensure  => file,
    content => "Hello from OpenVox! 🦊\nThis node is managed by an OpenVox server.\n",
    mode    => '0644',
  }
}

node default {
  notify { 'welcome_message':
    message => This node is managed by an OpenVox server, but has no configuration defined.',
  }
}
```

### *[Agent Node]* Enforce configuration

From now on, all you do on the agent node is trigger an OpenVox run and validate that it did what you want.
After the `puppet` service is enabled, it will continue to *converge* to the desired state every 30 minutes.

```console
$ sudo puppet agent -t
Info: Using environment 'production'
Info: Retrieving pluginfacts
Info: Retrieving plugin
Info: Loading facts
Notice: Requesting catalog from puppet.example.com:8140 (192.168.1.100)
Notice: Catalog compiled by puppet.example.com
Info: Caching catalog for agent1.example.com
Info: Applying configuration version '1778625673'
Notice: /Stage[main]/Main/Service[puppet]/ensure: ensure changed 'stopped' to 'running'
Info: /Stage[main]/Main/Service[puppet]: Unscheduling refresh on Service[puppet]
Notice: Applied catalog in 2.27 seconds
```

The `-t` or `--test` flag is named this way because in regular use you won't *push* configuration to your agent nodes.
You'll just let them retrieve and enforce configuration on their regular schedule.
The `test` mode lets you interactively observe the results of new configuration you've written.
{: .tip
}

## Next Steps

* Dive a little deeper into how the whole [OpenVox infrastructure is architected](architecture.html).
* Learn a bit more about the [Puppet Language](language.html) and classifying nodes.
