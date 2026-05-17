---
layout: default
title: "OpenVox Server Configuration Files: master.conf"
---

[new `auth.conf`]: ./config_file_auth.html
[deprecated]: ./deprecated_features.html
[`puppetserver.conf`]: ./config_file_puppetserver.html

The `master.conf` file configures how OpenVox Server handles [deprecated][] authorization methods for server endpoints. For an overview, see [OpenVox Server Configuration](./configuration.html).

> **Deprecation Note:** This file contains only the `allow-header-cert-info` parameter, and is deprecated in favor of authorization settings that are configured in the [new
> `auth.conf`][] file. Because this setting is deprecated, a default `master.conf` file is no longer included in the OpenVox Server package.

In `master.conf`, the `allow-header-cert-info` setting determines whether OpenVox Server should use authorization info from the `X-Client-Verify`, `X-Client-DN`, and `X-Client-Cert` HTTP headers. Its default
value is `false`.

The `allow-header-cert-info` setting is used to enable [external SSL termination](./external_ssl_termination.html). If the setting's value is set to `true`, OpenVox Server will ignore any certificate presented
to the Jetty web server, and will rely on header data to authorize requests. This is very dangerous unless you've secured your network to prevent any untrusted access to OpenVox Server.

When using the `allow-header-cert-info` setting in `master.conf`, you can change OpenVox's `ssl_client_verify_header` parameter to use another header name instead of `X-Client-Verify`. The `ssl_client_header`
parameter can rename `X-Client-DN`. The `X-Client-Cert` header can't be renamed.

The `allow-header-cert-info` parameter in `master.conf` applies only to HTTP endpoints served by the "server" service. The applicable endpoints include those listed in
[OpenVox V3 HTTP API](./http_api_index.html#puppet-v3-http-api). It does not apply to the endpoints listed in
[CA V1 HTTP API](./http_api_index.html#ca-v1-http-api) or to any [OpenVox Admin API][`puppetserver.conf`] endpoints.

## Supported Authorization Workflow

If you instead enable the `auth.conf` authorization method, the value of the `allow-header-cert-info` parameter in `auth.conf` controls how the user's identity is derived for
authorization purposes. In this case, OpenVox Server ignores the value of the `allow-header-cert-info` parameter in `master.conf`.

When using the `allow-header-cert-info` parameter in `auth.conf`, none of the `X-Client` headers can be renamed. Identity must be specified through the `X-Client-Verify`, `X-Client-DN`, and `X-Client-Cert`
headers.

The `allow-header-cert-info` parameter in `auth.conf`, applies to all HTTP endpoints that OpenVox Server handles, including those served by the "server" service, the CA API, and the OpenVox Admin API.

For additional information on the `allow-header-cert-info` parameter in `auth.conf`, see [Puppet Server Configuration Files: `auth.conf`][new `auth.conf`] and
[Configuring the Authorization Service in the `trapperkeeper-authorization` documentation](https://github.com/openvoxproject/trapperkeeper-authorization/blob/master/doc/authorization-config.md#allow-header-cert-info).

### HOCON `auth.conf` Example

```hocon
authorization: {
    version: 1
    # allow-header-cert-info: false
    rules: [
        {
            # Allow nodes to retrieve their own catalog
            match-request: {
                path: "^/puppet/v3/catalog/([^/]+)$"
                type: regex
                method: [get, post]
            }
            allow: "$1"
            sort-order: 500
            name: "puppetlabs catalog"
        },
        ...
    ]
}
```
