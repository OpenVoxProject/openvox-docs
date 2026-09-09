---
layout: default
title: "OpenVox Server Configuration Files: webserver.conf"
---

The `webserver.conf` file configures the OpenVox Server `webserver` service. For an overview, see [OpenVox Server Configuration](./configuration.html).
To configure the mount points for the OpenVox administrative API web applications, see the [`web-routes.conf` documentation](./config_file_web-routes.html).

## Examples

The `webserver.conf` file looks something like this:

```text
# Configure the webserver.
webserver: {
    # Log webserver access to a specific file.
    access-log-config: /etc/puppetlabs/puppetserver/request-logging.xml
    # Require a valid certificate from the client.
    client-auth: want
    # Listen for HTTPS traffic on all available hostnames.
    ssl-host: 0.0.0.0
    # Listen for HTTPS traffic on port 8140.
    ssl-port: 8140
}
```

These are the main values for managing an OpenVox Server installation. For further documentation, including a complete list of available settings and values, see
[Configuring the Webserver Service](https://github.com/OpenVoxProject/trapperkeeper-webserver/blob/main/doc/jetty-config.md).

By default, OpenVox Server is configured to use the correct OpenVox Server and certificate authority (CA)
certificates. If you're using an intermediate CA and providing your own certificates and keys, make sure the
SSL-related parameters in `webserver.conf` point to the correct file.

```text
webserver: {
    ...
    ssl-cert       : /etc/puppetlabs/puppet/ssl/certs/<certname>.pem
    ssl-key        : /etc/puppetlabs/puppet/ssl/private_keys/<certname>.pem
    ssl-ca-cert    : /etc/puppetlabs/puppetserver/ca/ca_crt.pem
    ssl-cert-chain : /etc/puppetlabs/puppetserver/ca/ca_crt.pem
    ssl-crl-path   : /etc/puppetlabs/puppet/ssl/crl.pem
}
```

Configuring an intermediate CA requires additional steps, which are described in [Intermediate CA](./intermediate_ca.html).
