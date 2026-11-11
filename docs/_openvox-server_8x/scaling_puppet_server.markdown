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

### Using a load balancer

You can also use a hardware or software load balancer to redirect requests more intelligently. A load balancer
can pass TLS through to the compilers or terminate TLS itself. These modes have different certificate and
authentication requirements; see [Configuring a load balancer](#configuring-a-load-balancer).

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

#### Using `SRV` records for other services

Agents use service-specific `SRV` records for catalog, CA, file serving, and transaction report requests. If a
service-specific record does not exist, the agent falls back to `_x-puppet._tcp.$srv_domain`.

| Service         | SRV record                              | Used for                                                                 |
| --------------- | --------------------------------------- | ------------------------------------------------------------------------ |
| OpenVox Server  | `_x-puppet._tcp.$srv_domain`            | Catalogs, facts, node data, and file bucket requests                     |
| CA              | `_x-puppet-ca._tcp.$srv_domain`         | Certificate requests and renewal, CA certificate and CRL downloads       |
| File server     | `_x-puppet-fileserver._tcp.$srv_domain` | File metadata and content, including `puppet:///` sources and pluginsync |
| Reports         | `_x-puppet-report._tcp.$srv_domain`     | Transaction reports saved through the REST report terminus               |

Reports sent by the `http` report processor go to the `reporturl` setting and do not use `SRV` records.

For services other than `puppet`, agents choose a server in this order:

1. Look up the service-specific `SRV` record. If it does not exist, look up `_x-puppet._tcp.$srv_domain`
   instead. If the service-specific record exists but none of its targets accepts a connection, the
   agent does not try `_x-puppet`.
2. If no `SRV` target accepted a connection, try the servers in the
   [`server_list` setting](/openvox/8.x/configuration.html#server_list). This step is skipped for CA
   requests when `ca_server` is set, and for report requests when `report_server` is set.
   If every server in `server_list` fails, the agent stops trying other options and that request fails.
3. If `server_list` is not set or was skipped, use `ca_server` for CA requests, `report_server` for
   reports, and `server` for everything else.

The `_x-puppet-fileserver` record applies to `puppet:///` sources that do not name a server. A source such
as `puppet://fileserver.example.com/path` connects directly to that host and does not use the record.

To direct file serving to a dedicated OpenVox Server, publish an `_x-puppet-fileserver` record for it:

```text
# Catalogs, facts, and other agent requests go to the compilers:
_x-puppet._tcp.example.com.             IN SRV 0 5 8140 compiler-a.example.com.
_x-puppet._tcp.example.com.             IN SRV 0 5 8140 compiler-b.example.com.

# File metadata and content go to a dedicated fileserver:
_x-puppet-fileserver._tcp.example.com.  IN SRV 0 5 8140 fileserver.example.com.
```

The dedicated fileserver must trust the same certificate authority, present a certificate valid for the
`SRV` target, authorize agent certificates, and serve the same environments and code as the compilers.
Otherwise, agents cannot retrieve file metadata or content.

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
   [load balancer](#choosing-a-tls-mode) in TLS passthrough mode, provide compilers with certificates
   using DNS Subject Alternative Names.

    Configure `dns_alt_names` in the `[main]` block of `puppet.conf` to cover every DNS name that might be
    used by an agent to access this server.

    ```text
    dns_alt_names = puppet,puppet.example.com,puppet.site-a.example.com
    ```

    If the agent or server has been run and already created a certificate, remove it by running
    `sudo /opt/puppetlabs/bin/puppet ssl clean`. If an agent has requested a certificate from the server, delete it there to
    re-issue a new one with the alt names: `puppetserver ca clean --certname server-2.example.com`.

1. Request a new certificate by running `puppet agent --test --waitforcert 10`.

1. Log into the CA server and run `puppetserver ca sign --certname server-2.example.com`.

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

## Configuring a load balancer

A load balancer distributes agent requests across the compilers. Point agents at the load balancer's hostname
in their `server` setting, not at individual compilers. Complete the compiler, certificate authority, report,
and [code deployment](#keeping-manifests-and-modules-synchronized-across-compilers) configuration before you put
the load balancer in front of the pool.

### Choosing a TLS mode

Load balancers usually operate in one of two TLS modes.

**TLS passthrough.** The load balancer forwards the TLS connection without decrypting it. OpenVox Server
terminates TLS and sees the agent's client certificate directly. This preserves client-certificate
authentication and is the simplest mode to operate. Compilers must have a certificate whose DNS names include
the load balancer's hostname; see [Certificates](#certificates). The
[example HAProxy configuration](#example-haproxy-configuration) uses this mode.

**TLS termination.** The load balancer terminates the agent's TLS connection and connects to OpenVox Server over
HTTP or a second TLS connection. OpenVox Server no longer sees the agent's certificate unless the load balancer
forwards it in HTTP headers. To configure this mode:

- Set `allow-header-cert-info: true` in the authorization configuration.
- Configure the load balancer to request and verify the agent's certificate against the CA.
- Discard any client-supplied `X-Client-*` values, then overwrite `X-Client-Verify` and `X-Client-DN` with
  values from the verified certificate. Set `X-Client-Cert` only when you use trusted facts; otherwise remove
  it. Without this, an agent can spoof another node's identity.
- Restrict compiler network access to the load balancer.
- If the load balancer connects to the compilers over TLS and they set `client-auth: need`, give the load
  balancer a client certificate that the CA in the compiler's `ssl-ca-cert` trusts. If it cannot, set
  `client-auth: want` on the compilers. With `want`, the TLS handshake succeeds without a client certificate,
  but `auth.conf` still requires a valid identity for agent endpoints.

See [External SSL Termination](./external_ssl_termination.html) for the required configuration and security
warning.

For most deployments, start with TLS passthrough. It avoids forwarding client identity in HTTP headers and the
security risk of trusting those headers. If you must inspect HTTP traffic at the load balancer, use TLS
termination and follow [External SSL Termination](./external_ssl_termination.html).

### Balancing requests

Use the least-connections algorithm (`leastconn` in HAProxy) as a starting point. Catalog compilation time
varies by node, so round robin can leave one compiler busy while another is idle. If your load balancer uses a
different name for this algorithm, choose the equivalent least-connections or least-outstanding-requests
option.

Do not load-balance certificate authority requests across compilers. Agents must send CA requests to the
central CA server, as described in [Centralizing the Certificate Authority](#centralizing-the-certificate-authority).

### Health checks and timeouts

Configure the load balancer to remove a compiler from the pool when OpenVox Server is not healthy. The Status
API's `simple` endpoint is designed for load balancers:

```text
GET https://compiler.example.com:8140/status/v1/simple
```

It returns `200` when the service is running and `503` when the service state is unknown or error. The
`services` endpoint with `level=critical` is also suitable for frequent health checks. The packaged `auth.conf`
allows unauthenticated access to both endpoints; if you tightened `auth.conf`, allow the status endpoint you
use (`/status/v1/simple` or `/status/v1/services`).

The packaged `webserver.conf` sets `client-auth: want`, so an HTTPS health check works without a client
certificate. If you changed `client-auth` to `need`, the check must present a client certificate that the
webserver trusts, or you can keep the TCP health check. The
[example HAProxy configuration](#example-haproxy-configuration) shows how to add the certificate.

The agent's default `http_read_timeout` is 10 minutes; `puppet config print http_read_timeout` reports `600`.
Set the load balancer's client and server timeouts longer than the agent's `http_read_timeout` and your slowest
catalog compilation. A timeout shorter than a normal compile causes retries, which adds load to the remaining
compilers. See [Status API: Simple](./status-api/v1/simple.html) and
[Status API: Services](./status-api/v1/services.html) for endpoint details.

### Certificates

For TLS passthrough, agents connect to the load balancer's DNS name, but the compiler presents its own
certificate. Include the load balancer hostname in each compiler's `dns_alt_names` in the `[main]` block of
`puppet.conf` before its certificate request is made. See
[Creating and configuring compilers](#creating-and-configuring-compilers).

The CA server must sign certificates that contain subject alternative names. In `ca.conf` on the CA server, set:

```text
certificate-authority: {
    allow-subject-alt-names: true
}
```

Set this before the CA signs the compiler's certificate request, then restart `puppetserver` on the CA server.
If a compiler already has a certificate without the load balancer name, replace it. Run all of the following
commands as root:

1. Remove the compiler from the load balancer pool if your load balancer supports manual removal. Then run
   `systemctl stop puppetserver` so it stops using the old certificate before you revoke it. If you cannot remove
   it manually, wait for the health check to remove it after the service stops.

1. On the CA server, run `puppetserver ca clean --certname <compiler-certname>`.

1. On the compiler, remove the old certificate and key with `puppet ssl clean`.

1. Request a new certificate with `puppet ssl bootstrap --waitforcert 10`. The request includes the `dns_alt_names`
   set in `puppet.conf`, so confirm that setting includes the load balancer name.

1. On the CA server, sign the request with `puppetserver ca sign --certname <compiler-certname>`.

1. Run `systemctl start puppetserver` on the compiler.

For TLS termination, agents validate the certificate on the load balancer instead. Install a certificate that
your agents trust on the load balancer. If the load balancer connects to the compilers over TLS, those
compiler certificates must also be valid for the names the load balancer uses.

### Example HAProxy configuration

The following minimal example uses TLS passthrough and least-connections balancing. The `bind *:8140` line
assumes a dedicated load balancer host, because `puppetserver` also listens on port 8140:

```text
global
    log /dev/log local0
    maxconn 4096

defaults
    mode tcp
    log global
    option tcplog
    timeout connect 10s
    timeout client 15m
    timeout server 15m

frontend openvox_server
    bind *:8140
    default_backend openvox_compilers

backend openvox_compilers
    balance leastconn
    server compiler1 compiler1.example.com:8140 check
    server compiler2 compiler2.example.com:8140 check
```

On Enterprise Linux hosts with SELinux enforcing, HAProxy cannot bind port 8140, which is labeled `puppet_port_t`,
by default. Allow it before you start HAProxy, for example with `setsebool -P haproxy_connect_any 1`.

This example performs a TCP health check, which detects a closed port but not an unhealthy OpenVox Server
service. To check `/status/v1/simple` over TLS instead, change `check` to `check check-ssl` in each `server`
line and add an HTTP check to the backend:

```text
backend openvox_compilers
    balance leastconn
    option httpchk GET /status/v1/simple
    http-check expect status 200
    server compiler1 compiler1.example.com:8140 check check-ssl verify required ca-file /etc/haproxy/openvox-ca.pem
    server compiler2 compiler2.example.com:8140 check check-ssl verify required ca-file /etc/haproxy/openvox-ca.pem
```

`check-ssl` verifies the server certificate by default, and HAProxy refuses the configuration without a CA file. The
`ca-file` must contain the CA that signed the compiler certificates; `/etc/haproxy/openvox-ca.pem` is a placeholder.
This check sends no client certificate. If `client-auth` is `need`, add `crt <client.pem>` to each `server`
line so the health check sends a client certificate. Passthrough traffic is not affected. Use a PEM that contains
the certificate and key, or provide the matching `.key` file. The certificate must be trusted by the CA in the
compiler's `ssl-ca-cert`. The 15-minute timeouts exceed the agent default of 10 minutes; tune them to your
environment.

### Testing failover

After you configure the load balancer, test the full path:

1. Run `puppet config print server ca_server` on a test node and confirm the output shows the load balancer for
   `server` and the CA server for `ca_server`, then run `puppet agent --test`.

1. Run `systemctl stop puppetserver` on one compiler, wait for the health check to remove it from the pool
   (HAProxy defaults: `fall` 3 and `inter` 2s, so about six seconds), and confirm it is down in the load
   balancer's statistics page or log (`Server openvox_compilers/compiler1 is DOWN`).

1. Run `puppet agent --test` again and confirm the agent succeeds through another compiler.

1. Run `systemctl start puppetserver` on the compiler and confirm it returns to the pool.
