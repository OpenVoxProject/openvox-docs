---
layout: default
title: "Scaling OpenVox Server with compilers"
---

To scale OpenVox Server for many thousands of nodes, you'll need to add servers dedicated to catalog compilation.
These are known as **compilers**, and are simply additional load-balanced OpenVox Servers that independently
compile catalogs for agents from a shared codebase.

For a reference architecture covering the full load-balanced stack (HAProxy, r10k, Foreman, and automation),
see [Load balanced architecture](https://voxpupuli.org/docs/arch_load_balanced) on the Vox Pupuli site.

## Planning your load-balancing strategy

The rest of your configuration depends on how you plan on distributing the agent load. Determine what your
deployment will look like before you add any compilers, but **implement load balancing as the last step** only
after you have the infrastructure in place to support it.

### Using round-robin DNS

Leave all of your agents pointed at the same OpenVox Server hostname, then configure your site's DNS to
arbitrarily route all requests directed at that hostname to the pool of available servers.

For instance, if all of your agent nodes are configured with `server = puppet.example.com`, configure a DNS name such as:

```text
# IP address of server 1:
puppet.example.com. IN A 192.0.2.50
# IP address of server 2:
puppet.example.com. IN A 198.51.100.215
```

For this option, configure your servers with `dns_alt_names` before their certificate request is made.

### Using a hardware load balancer

You can also use a hardware load balancer or a load-balancing proxy webserver to redirect requests more
intelligently. Depending on your configuration (for instance, SSL using either raw TCP proxying or acting as
its own SSL endpoint), you might also need to use other procedures in this document.

Configuring a load balancer depends on the product, and is beyond the scope of this document.

### Using DNS `SRV` Records

You can use DNS `SRV` records to assign a pool of OpenVox Servers for agents to communicate with. This requires
a DNS service capable of `SRV` records, which includes all major DNS software.

> **Note:** This method makes a large number of DNS requests. Request timeouts are completely under the DNS
> server's control and agents cannot cancel requests early. SRV records don't interact well with static servers
> set in the config file. Please keep these potential pitfalls in mind when configuring your DNS!

Configure each of your agents with a `srv_domain` instead of a `server` in `puppet.conf`:

```text
[main]
use_srv_records = true
srv_domain = example.com
```

Agents will then look up a `SRV` record at `_x-puppet._tcp.example.com` when they need to talk to an OpenVox Server.

```text
# Equal-weight load balancing between server-a and server-b:
_x-puppet._tcp.example.com. IN SRV 0 5 8140 server-a.example.com.
_x-puppet._tcp.example.com. IN SRV 0 5 8140 server-b.example.com.
```

You can also implement more complex configurations. For instance, if all devices in site A are configured with
a `srv_domain` of `site-a.example.com`, and all nodes in site B are configured to `site-b.example.com`, you
can configure them to prefer a server in the local site but fail over to the remote site:

```text
# Site A has two servers - server-1 is beefier, give it 75% of the load:
_x-puppet._tcp.site-a.example.com. IN SRV 0 75 8140 server-1.site-a.example.com.
_x-puppet._tcp.site-a.example.com. IN SRV 0 25 8140 server-2.site-a.example.com.
_x-puppet._tcp.site-a.example.com. IN SRV 1 5 8140 server.site-b.example.com.

# For site B, prefer the local server unless it's down, then fail back to site A
_x-puppet._tcp.site-b.example.com. IN SRV 0 5 8140 server.site-b.example.com.
_x-puppet._tcp.site-b.example.com. IN SRV 1 75 8140 server-1.site-a.example.com.
_x-puppet._tcp.site-b.example.com. IN SRV 1 25 8140 server-2.site-a.example.com.
```

## Centralizing the Certificate Authority

Additional OpenVox Servers should only share the burden of compiling and serving catalogs, which is why they're
typically referred to as "compilers". Any certificate authority functions should be delegated to a single server.

Before you centralize this functionality, ensure that the single server that you want to use as the central CA
is reachable at a unique hostname other than (or in addition to) `puppet`. Next, point all agent requests to
the centralized CA server, either by configuring each agent or through DNS `SRV` records.

### Directing individual agents to a central CA

On every agent, set the `ca_server` setting in `puppet.conf` (in the `[main]` configuration block) to the
hostname of the server acting as the certificate authority. If you have a large number of existing nodes, it is
easiest to do this by managing `puppet.conf` with an OpenVox module and a template.

> **Note:** Set this setting _before_ provisioning new nodes, or they won't be able to complete their initial agent run.

### Pointing DNS `SRV` records at a central CA

If you [use `SRV` records for agents](#using-dns-srv-records), you can use the `_x-puppet-ca._tcp.$srv_domain`
DNS name to point clients to one specific CA server, while the `_x-puppet._tcp.$srv_domain` DNS name handles
most of their requests and can point to a set of compilers.

## Creating and configuring compilers

To add a compiler to your deployment, begin by [installing and configuring OpenVox Server](./install_from_packages.html) on it.

Before running `puppet agent` or starting `puppetserver` on the new compiler:

1. In the compiler's `puppet.conf`, in the `[main]` configuration block, set `ca_server` to the hostname of
   the server acting as the certificate authority.

1. In the compiler's `webserver.conf` file, add and set the following SSL settings:
    - ssl-cert
    - ssl-key
    - ssl-ca-cert
    - ssl-crl-path

1. [Disable OpenVox Server's certificate authority services](./configuration.html#service-bootstrapping).
   If an `ssldir` is configured, make sure it's set in the `[main]` block of `puppet.conf` only.

1. If you're using the [DNS round robin method](#using-round-robin-dns) of agent load balancing, or a
   [load balancer](#using-a-hardware-load-balancer) in TCP proxying mode, provide compilers with certificates
   using DNS Subject Alternative Names.

    Configure `dns_alt_names` in the `[main]` block of `puppet.conf` to cover every DNS name that might be
    used by an agent to access this server.

    ```text
    dns_alt_names = puppet,puppet.example.com,puppet.site-a.example.com
    ```

    If the agent or server has been run and already created a certificate, remove it by running
    `sudo puppet ssl clean`. If an agent has requested a certificate from the server, delete it there to
    re-issue a new one with the alt names: `puppetserver ca clean server-2.example.com`.

1. Request a new certificate by running `puppet agent --test --waitforcert 10`.

1. Log into the CA server and run `puppetserver ca sign server-2.example.com`.

## Centralizing reports and exported resources

If you use an HTTP report processor, point your primary server and all compilers at the same shared report
server in order to see all of your agents' reports.

If you use exported resources, use OpenVoxDB and point your primary server and all compilers at a shared
OpenVoxDB instance. A reasonably robust OpenVoxDB server can handle many compilers and many thousands of agents.

See the [OpenVoxDB documentation](/openvoxdb/latest/) for instructions on deploying an OpenVoxDB
server, then configure every compiler to use it. Note that every server and compiler must have its own
[certificate allowlist entry](/openvoxdb/latest/configure.html) if you're using HTTPS certificates
for authorization.

## Keeping manifests and modules synchronized across compilers

You must ensure that all compilers have identical copies of your manifests, modules, and external node
classifier data.

The recommended approach is to use [r10k](https://github.com/voxpupuli/r10k) with a webhook to trigger
automatic code deployment to all compilers on every push to your control repository. The Vox Pupuli
[webhook-go](https://github.com/voxpupuli/webhook-go) service provides a lightweight webhook receiver
that calls r10k on each compiler. See the [load balanced architecture guide](https://voxpupuli.org/docs/arch_load_balanced)
for a full reference setup.

Other options include:

- Running r10k manually or via `cron` on each compiler.
- Running an out-of-band `rsync` task via `cron`.
- Configuring `puppet agent` on each compiler to point to a designated primary server, then use OpenVox itself
  to distribute the modules.
