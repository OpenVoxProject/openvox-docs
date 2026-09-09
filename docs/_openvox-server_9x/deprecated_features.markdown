---
layout: default
title: "OpenVox Server: Deprecated Features"
---

The following features / configuration settings are deprecated and will be removed in a future major release of OpenVox Server.

## `certificate-status` settings

### Now

If the `certificate-authority.certificate-status.authorization-required` setting is `false`, all requests that are successfully validated by SSL (if applicable for the port settings on the server) are permitted
to use the [Certificate Status](https://github.com/openvoxproject/openvox/blob/master/api/docs/http_certificate_status.md) HTTP API endpoints. This includes requests which do not provide an SSL client certificate.

If the `certificate-authority.certificate-status.authorization-required` setting is `true` or not specified and the `puppet-admin.client-whitelist` setting has one or more entries, only the requests whose
Common Name in the SSL client certificate subject matches one of the `client-whitelist` entries are permitted to use the certificate status HTTP API endpoints.

For any other configuration, requests are only permitted to access the certificate status HTTP API endpoints if allowed per the rule definitions in the `trapperkeeper-authorization` "auth.conf" file. See the
[puppetserver "auth.conf"](./config_file_auth.html) page for more information.

### In a Future Major Release

The `certificate-status` settings will be ignored completely by OpenVox Server. Requests made to the `certificate-status` HTTP API will only be allowed per the `trapperkeeper-authorization` "auth.conf"
configuration.

### Detecting and Updating

Look at the `certificate-status` settings in your configuration. If `authorization-required` is set to `false` or `client-whitelist` has one or more entries, these settings would be used to authorize access to
the certificate status HTTP API instead of `trapperkeeper-authorization`.

If `authorization-required` is set to `true` or is not specified and if the `client-whitelist` was empty, you could just remove the `certificate-authority` section from your configuration. The only behavior
that would change in OpenVox Server from doing this would be that a warning message would no longer be written to the "puppetserver.log" file at startup.

If `authorization-required` is set to `false`, you would need to create a corresponding rule in the `trapperkeeper-authorization` file which would allow unauthenticated client access to the certificate status
API.

For example:

```hocon
authorization: {
    version: 1
    rules: [
            {
                match-request: {
                    path: "/certificate_status/"
                    type: path
                    method: [ get, put, delete ]
                }
                allow-unauthenticated: true
                sort-order: 200
                name: "certificate_status"
            },
            {
                match-request: {
                    path: "/certificate_statuses/"
                    type: path
                    method: get
                }
                allow-unauthenticated: true
                sort-order: 200
                name: "certificate_statuses"
            },
            ...
    ]
}
```

If `authorization-required` is set to `true` or not set but the `client-whitelist` has one or more custom entries in it, you would need to create a corresponding rule in the `trapperkeeper-authorization`
"auth.conf" file which would allow only specific clients access to the certificate status API.

For example, the current certificate status configuration could have:

```hocon
certificate-authority:
    certificate-status: {
        client-whitelist: [ admin1, admin2 ]
    }
}
```

Corresponding `trapperkeeper-authorization` rules could have:

```hocon
authorization: {
    version: 1
    rules: [
            {
                match-request: {
                    path: "/certificate_status/"
                    type: path
                    method: [ get, put, delete ]
                }
                allow: [ admin1, admin2 ]
                sort-order: 200
                name: "certificate_status"
            },
            {
                match-request: {
                    path: "/certificate_statuses/"
                    type: path
                    method: get
                }
                allow: [ admin1, admin2 ]
                sort-order: 200
                name: "certificate_statuses"
            },
            ...
    ]
}
```

After adding the desired rules to the `trapperkeeper-authorization` "auth.conf" file, remove the `certificate-authority` section from the "puppetserver.conf" file and restart the puppetserver service.

### Context

In previous OpenVox Server releases, there was no unified mechanism for controlling access to the various endpoints that OpenVox Server hosts. OpenVox Server used core OpenVox "auth.conf" to authorize requests
handled by its core API endpoints, and custom client whitelists for the CA and Admin endpoints. The custom client whitelists do not provide granular enough control to meet some use cases.

`trapperkeeper-authorization` unifies authorization configuration across all of these endpoints into a single file and provides more granular control.

## `puppet-admin` Settings

### Now

If the `puppet-admin.authorization-required` setting is `false`, all requests that are successfully validated by SSL (if applicable for the port settings on the server) are permitted to use the `puppet-admin`
HTTP API endpoints. This includes requests which do not provide an SSL client certificate.

If the `puppet-admin.authorization-required` setting is `true` or not specified and the `puppet-admin.client-whitelist` setting has one or more entries, only the requests whose Common Name in the SSL client
certificate subject matches one of the `client-whitelist` entries are permitted to use the `puppet-admin` HTTP API endpoints.

For any other configuration, requests are only permitted to access the `puppet-admin` HTTP API endpoints if allowed per the rule definitions in the `trapperkeeper-authorization` "auth.conf" file. See the
[puppetserver "auth.conf"](./config_file_auth.html) page for more information.

### In a Future Major Release

The `puppet-admin` settings will be ignored completely by OpenVox Server. Requests made to the `puppet-admin` HTTP API will only be allowed per the `trapperkeeper-authorization` "auth.conf" configuration.

### Detecting and Updating

Look at the `puppet-admin` settings in your configuration. If `authorization-required` is set to `false` or `client-whitelist` has one or more entries, these settings would be used to authorize access to the
`puppet-admin` HTTP API instead of `trapperkeeper-authorization`.

If `authorization-required` is set to `true` or is not specified and if the `client-whitelist` was empty, you could just remove the `puppet-admin` section from your configuration and restart your puppetserver
service in order for OpenVox Server to start using the `trapperkeeper-authorization` "auth.conf" file. The only behavior that would change in OpenVox Server from doing this would be that a warning message would
no longer be written to the puppetserver.log file.

If `authorization-required` is set to `false`, you would need to create corresponding rules in the `trapperkeeper-authorization` file which would allow unauthenticated client access to the "puppet-admin" API
endpoints.

For example:

```hocon
authorization: {
    version: 1
    rules: [
            {
                match-request: {
                    path: "/puppet-admin-api/v1/environment-cache"
                    type: path
                    method: delete
                }
                allow-unauthenticated: true
                sort-order: 200
                name: "environment-cache"
            },
            {
                match-request: {
                    path: "/puppet-admin-api/v1/jruby-pool"
                    type: path
                    method: delete
                }
                allow-unauthenticated: true
                sort-order: 200
                name: "jruby-pool"
            },
            ...
     ]
}
```

If `authorization-required` is set to `true` or not set but the `client-whitelist` has one or more custom entries in it, you would need to create corresponding rules in the `trapperkeeper-authorization`
"auth.conf" file which would allow only specific clients access to the "puppet-admin" API endpoints.

For example, the current "puppet-admin" configuration could have:

```hocon
puppet-admin: {
    client-whitelist: [ admin1, admin2 ]
}
```

Corresponding `trapperkeeper-authorization` rules could have:

```hocon
authorization: {
    version: 1
    rules: [
            {
                match-request: {
                    path: "/puppet-admin-api/v1/environment-cache"
                    type: path
                    method: delete
                }
                allow: [ admin1, admin2 ]
                sort-order: 200
                name: "environment-cache"
            },
            {
                match-request: {
                    path: "/puppet-admin-api/v1/jruby-pool"
                    type: path
                    method: delete
                }
                allow: [ admin1, admin2 ]
                sort-order: 200
                name: "jruby-pool"
            },
            ...
     ]
}
```

After adding the desired rules to the `trapperkeeper-authorization` "auth.conf" file, remove the `puppet-admin` section from the "puppetserver.conf" file and restart the puppetserver service.

### Context

In previous OpenVox Server releases, there was no unified mechanism for controlling access to the various endpoints that OpenVox Server hosts. OpenVox Server used core OpenVox "auth.conf" to authorize requests
handled by its core API endpoints, and custom client whitelists for the CA and Admin endpoints. The custom client whitelists do not provide granular enough control to meet some use cases.

`trapperkeeper-authorization` unifies authorization configuration across all of these endpoints into a single file and provides more granular control.

## `master.allow-header-cert-info` setting

### Now

The `master.allow-header-cert-info` setting in [`puppetserver.conf`](./config_file_puppetserver.html) controls whether OpenVox Server reads client identity, such as the client's certificate name, from HTTP headers
instead of from the SSL connection. This is used when OpenVox Server runs behind a TLS-terminating proxy or load balancer that authenticates the client certificate and forwards the details in headers.

OpenVox Server also accepts an equivalent `allow-header-cert-info` setting in the `authorization` section of the [`trapperkeeper-authorization` "auth.conf"](./config_file_auth.html) file. If
`master.allow-header-cert-info` is set, OpenVox Server logs a deprecation warning.

### In a Future Major Release

The `master.allow-header-cert-info` setting will be ignored completely. Whether OpenVox Server trusts certificate information from HTTP headers will be controlled only by the
`authorization.allow-header-cert-info` setting.

### Detecting and Updating

Look for `allow-header-cert-info` in the `master` section of your `puppetserver.conf` file. Set `allow-header-cert-info` in the `authorization` section of your `trapperkeeper-authorization` "auth.conf" file to
the same value, then remove the setting from the `master` section.

Only enable `allow-header-cert-info` when OpenVox Server is behind a trusted TLS-terminating proxy that sets these headers.
If it is enabled when requests can reach OpenVox Server directly, clients can spoof their identity through the headers.
{: .warning }

### Context

Header-based certificate information was historically configured separately for the legacy request handler and for `trapperkeeper-authorization`. Consolidating on the `authorization` setting keeps all
request-authorization configuration in the `trapperkeeper-authorization` "auth.conf" file.

## `jruby-puppet` `master-*` directory settings

### Now

The `jruby-puppet` section of [`puppetserver.conf`](./config_file_puppetserver.html) accepts both the `server-*` directory settings and their older `master-*` equivalents. The `master-*` settings are deprecated:

| Deprecated setting | Replacement |
| --- | --- |
| `master-conf-dir` | `server-conf-dir` |
| `master-code-dir` | `server-code-dir` |
| `master-var-dir` | `server-var-dir` |
| `master-run-dir` | `server-run-dir` |
| `master-log-dir` | `server-log-dir` |

### In a Future Major Release

The `master-*` directory settings will be removed. Use the `server-*` settings instead.

### Detecting and Updating

Look in the `jruby-puppet` section of your `puppetserver.conf` file for any of the `master-*` directory settings listed above. Rename each to its `server-*` equivalent; the values do not change.

### Context

These settings were renamed as part of moving away from "master" terminology toward "server". The `server-*` names are the supported form.
