---
layout: default
title: "OpenVox Server: External SSL Termination"
canonical: "/puppetserver/latest/external_ssl_termination.html"
---

OpenVox Server normally terminates TLS itself: its embedded web server presents the server certificate and verifies each agent's client certificate during the handshake. You can instead terminate TLS on a proxy in front of OpenVox Server. The proxy verifies the agent's certificate, passes what it learned to OpenVox Server in HTTP headers, and OpenVox Server listens on plain HTTP.

## When to use this

A single OpenVox Server with no special requirements doesn't need a proxy. Its built-in TLS works, and a proxy adds a component to run, a trust boundary to protect, and a CRL to reload. Terminate TLS externally when you want one of these:

- **Routing by URL.** A load balancer that passes TLS through in TCP mode can only balance whole connections. A proxy that terminates TLS can see the request path, so it can send certificate requests to the CA server and catalog requests to a pool of compilers, retry a failed compiler, or run per-endpoint health checks.
- **One place for TLS policy.** Protocol versions, cipher suites, certificate handling, and access logging are managed in the proxy your team already runs, with the tooling and monitoring it already has, instead of in the OpenVox Server web server settings.
- **Protection in front of the server.** The proxy can rate-limit agents, restrict which endpoints are reachable from which networks, and keep the OpenVox Server port off the network entirely.
- **Serving other things on the same name and port.** The proxy can serve other content or services alongside OpenVox Server, which the built-in web server cannot do.

Use the following steps to configure external SSL termination. The [nginx example](#example-nginx) at the end of this page is a complete, tested proxy configuration.

## Disable HTTPS for OpenVox Server

Turn off SSL and have OpenVox Server use HTTP instead: remove the `ssl-port`, `ssl-host`, and `client-auth` settings from `/etc/puppetlabs/puppetserver/conf.d/webserver.conf` and replace them with `port` and `host` settings. Bind to the loopback address unless the proxy runs on another host, and use a port other than 8140 so the proxy can keep serving agents on 8140:

```hocon
webserver: {
    access-log-config: /etc/puppetlabs/puppetserver/request-logging.xml
    host: 127.0.0.1
    port: 8141
}
```

See [Configuring the Webserver Service](https://github.com/openvoxproject/trapperkeeper-webserver/blob/main/doc/jetty-config.md) for more information on configuring the web server service.

## Allow client certificate data from HTTP headers

When using external SSL termination, OpenVox Server expects to receive client certificate information in HTTP headers.

By default, reading this data from headers is disabled. To allow OpenVox Server to recognize it, set `allow-header-cert-info: true` in the `authorization` section of `/etc/puppetlabs/puppetserver/conf.d/auth.conf`:

```hocon
authorization: {
    version: 1
    allow-header-cert-info: true
    rules: [
        ...
    ]
}
```

See [auth.conf](config_file_auth.html#allow-header-cert-info) for more information on this setting.

> **WARNING**: Setting `allow-header-cert-info` to `true` puts OpenVox Server in an incredibly vulnerable state. Take extra caution to ensure it is **absolutely not reachable** by an untrusted network.
>
> With `allow-header-cert-info` set to `true`, authorization code uses only the client HTTP header values, not an SSL-layer client certificate, to determine the client subject name, authentication status, and trusted facts. This is true even if the web server is hosting an HTTPS connection.
> This applies to validation of the client via rules in the [auth.conf](config_file_auth.html) file and any [trusted facts][trusted] extracted from certificate extensions.
>
> Anything that can open a connection to the OpenVox Server port can claim to be any node by sending the headers itself. Bind OpenVox Server to the loopback address, or firewall its port so that only the proxy can reach it.

## Reload OpenVox Server

Reload OpenVox Server for the configuration changes to take effect.

## Configure the proxy to set HTTP headers

The device that terminates SSL for OpenVox Server must extract information from the client's certificate and insert that information into three HTTP headers. The proxy must also set these headers on every request, so that a client cannot supply them itself. See the documentation for your SSL terminator for details, or use the [nginx example](#example-nginx) below.

The headers you need to set are `X-Client-Verify`, `X-Client-DN`, and `X-Client-Cert`.

### `X-Client-Verify`

Mandatory. Must be either `SUCCESS` if the certificate was validated, or something else if not. (The convention is to use `NONE` when a certificate wasn't presented, and `FAILED:reason` for other validation failures.) OpenVox Server uses this to authorize requests; only requests with a value of `SUCCESS` are considered authenticated.

### `X-Client-DN`

Mandatory. Must be the [Subject DN][] of the agent's certificate, if a certificate was presented. OpenVox Server uses this to authorize requests. Both the RFC 2253 form (`CN=agent1.example.com`) and the older OpenSSL form (`/CN=agent1.example.com`) are accepted.

[subject dn]: /docs/background/ssl/cert_anatomy.html#the-subject-dn-cn-certname-etc

### `X-Client-Cert`

Optional. Should contain the client's [PEM-formatted][pem format] (Base-64) certificate (if a certificate was presented) in a single URI-encoded string. Note that URL encoding is not sufficient; all space characters must be encoded as `%20` and not `+` characters. A raw PEM certificate is not a valid header value, because it contains line breaks.

> **Note:** OpenVox Server only uses the value of this header to extract [trusted facts][trusted] from extensions in the client certificate. If you aren't using trusted facts, you can reduce the size of the request payload by omitting the `X-Client-Cert` header.

[pem format]: /docs/background/ssl/cert_anatomy.html#pem-file
[trusted]: /openvox/latest/lang_facts_and_builtin_vars.html#trusted-facts

## Example: nginx

This configuration runs nginx on the same host as OpenVox Server, listening on port 8140 so that agents need no changes. It was tested with nginx 1.29 in front of OpenVox Server 8.16.0: agents bootstrap their certificates, receive catalogs, and get trusted facts through the proxy.

You need nginx 1.13.5 or later, which provides the `$ssl_client_escaped_cert` variable.

On the CA server, nginx reads the server certificate and key from the Puppet SSL directory and the CA certificate and CRL from the CA directory. The nginx master process runs as root on package installs and reads these files when it starts, so you don't need to change their permissions.
On a compiler that is not the CA, use `/etc/puppetlabs/puppet/ssl/certs/ca.pem` and `/etc/puppetlabs/puppet/ssl/crl.pem` instead of the CA directory files.

Replace `puppet.example.com` with your server's certname:

```nginx
upstream openvoxserver {
    server 127.0.0.1:8141;
}

server {
    listen 8140 ssl;
    server_name puppet.example.com;

    ssl_certificate        /etc/puppetlabs/puppet/ssl/certs/puppet.example.com.pem;
    ssl_certificate_key    /etc/puppetlabs/puppet/ssl/private_keys/puppet.example.com.pem;
    ssl_client_certificate /etc/puppetlabs/puppetserver/ca/ca_crt.pem;
    ssl_crl                /etc/puppetlabs/puppetserver/ca/ca_crl.pem;
    ssl_verify_client      optional;

    client_max_body_size 50m;

    location / {
        proxy_pass http://openvoxserver;
        proxy_read_timeout 300s;
        proxy_set_header Host $host;
        proxy_set_header X-Client-Verify $ssl_client_verify;
        proxy_set_header X-Client-DN     $ssl_client_s_dn;
        proxy_set_header X-Client-Cert   $ssl_client_escaped_cert;
    }
}
```

What each part does:

- **`ssl_verify_client optional`**: An agent that doesn't have a certificate yet must still reach the CA endpoints to submit its certificate request and download the signed certificate. `on` would reject it during the handshake.
  With `optional`, nginx verifies any certificate that is presented and rejects an invalid or revoked one itself with an HTTP 400 error, before the request reaches OpenVox Server. Don't use `optional_no_ca`, which skips verification.
- **`ssl_verify_depth`**: The default of 1 covers the standard OpenVox CA layout, in which an intermediate CA signs agent certificates and the root CA is the trust anchor. Raise it only if your chain has more intermediate certificates, for example with an [external CA](intermediate_ca.html).
- **`ssl_crl`**: nginx reads the CRL when it starts or reloads its configuration, and OpenVox Server does not check the CRL itself in this mode. After `puppetserver ca revoke` or `puppetserver ca clean`, reload nginx (`nginx -s reload`) or the revoked agent keeps getting catalogs.
- **`client_max_body_size`**: The default of 1 MB applies to the facts sent with each catalog request and to each report, both of which can exceed it on large nodes. nginx rejects a larger request with HTTP 413.
- **`proxy_read_timeout`**: The default of 60 seconds is shorter than a slow catalog compile. Set it to at least the longest compile time you expect, or agents receive HTTP 504 errors.
- **`proxy_set_header`**: nginx replaces any `X-Client-*` headers a client sends with its own values, so a client cannot authenticate as another node through the proxy. The direct OpenVox Server port has no such protection, which is why it must be bound to the loopback address.

The `puppetserver ca` subcommands keep working. They connect to the CA over HTTPS using the server's own certificate, so they go through nginx like any agent.

### Verify the setup

Run an agent against the proxy:

```console
puppet agent --test --server puppet.example.com
```

To confirm that the headers carry the certificate details, add a resource to the node's catalog that prints its trusted facts:

```puppet
notify { "certname=${trusted['certname']} authenticated=${trusted['authenticated']}": }
```

The agent run should print `authenticated=remote` and the agent's certname. If the certificate request contains [extensions](/openvox/latest/ssl_attributes_extensions.html), `$trusted['extensions']` is populated only when the `X-Client-Cert` header is set.

### Compilers behind one proxy

With [compilers](scaling_puppet_server.html#creating-and-configuring-compilers), one proxy can terminate TLS for the whole pool and route by path: certificate requests go to the CA server, everything else is balanced across the compilers.
This was tested with a CA server and a compiler behind one nginx: the compiler requested its own certificate through the proxy, and agents received catalogs compiled by the compiler.

Compared with the single-host example:

1. Make the `webserver.conf` and `auth.conf` changes on the CA server and on every compiler.
   The compilers can't listen on the loopback address, because the proxy reaches them over the network, so set `host` to the address of a private interface and firewall the port so that only the proxy can connect. Traffic between the proxy and the compilers is plain HTTP.
1. Run the proxy on the CA server, so that it can read the CA certificate and CRL directly, and so that `puppet.example.com` resolves to the proxy for agents and compilers alike. The certificate the proxy presents must be valid for that name; the CA server's own certificate is, if `puppet.example.com` is its certname or one of its `dns_alt_names`.
1. Replace the single `upstream` and `location` blocks with a pool of compilers and a separate route for the CA:

   ```nginx
   upstream compilers {
       server compiler1.example.com:8141;
       server compiler2.example.com:8141;
   }

   server {
       # listen, ssl_*, and client_max_body_size settings as in the single-host example

       location /puppet-ca/ {
           proxy_pass http://127.0.0.1:8141;
           include /etc/nginx/openvox_headers.conf;
       }

       location / {
           proxy_pass http://compilers;
           include /etc/nginx/openvox_headers.conf;
       }
   }
   ```

   Put the shared `proxy_read_timeout` and the four `proxy_set_header` lines from the single-host example in `/etc/nginx/openvox_headers.conf`, so that both locations send the same headers.

Requests for other endpoints, such as `/status/`, go to the compilers under this configuration. Monitor each server directly on its HTTP port instead.

If the proxy runs on a host other than the CA server, it has no local copy of the CRL. Fetch it from the CA on a timer and reload nginx when it changes:

```console
curl --silent --cacert /etc/puppetlabs/puppet/ssl/certs/ca.pem --header 'Accept: text/plain' \
  https://puppet.example.com:8140/puppet-ca/v1/certificate_revocation_list/ca --output /etc/nginx/ca_crl.pem
```
