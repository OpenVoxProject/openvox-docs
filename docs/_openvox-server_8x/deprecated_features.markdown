---
layout: default
title: "OpenVox Server: Deprecated Features"
---

The following features / configuration settings are deprecated and will be removed in a future major release of OpenVox Server.

## `certificate-status` settings

### Now

If the `certificate-authority.certificate-status.authorization-required` setting is `false`, all requests that are successfully validated by SSL (if applicable for the port settings on the server) are permitted
to use the [Certificate Status](https://github.com/openvoxproject/penvox/blob/master/api/docs/http_certificate_status.md) HTTP API endpoints. This includes requests which do not provide an SSL client certificate.

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
handled by the primary service and custom client whitelists for the CA and Admin endpoints. The custom client whitelists do not provide granular enough control to meet some use cases.

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
handled by the master service and custom client whitelists for the CA and Admin endpoints. The custom client whitelists do not provide granular enough control to meet some use cases.

`trapperkeeper-authorization` unifies authorization configuration across all of these endpoints into a single file and provides more granular control.

## OpenVox's "resource_types" API endpoint

### Now

The `resource_type` and `resource_types` HTTP APIs were removed in OpenVox Server 5.0.

### Previously

The [`resource_type` and `resource_types` OpenVox HTTP API endpoints](/openvox/latest/http_api/http_resource_type.html) return information about classes, defined types, and node definitions.

The [`environment_classes` HTTP API in OpenVox Server](./puppet-api/v3/environment_classes.html) serves as a replacement for the OpenVox resource type API for classes.

### Detecting and Updating

If your application calls the `resource_type` or `resource_types` HTTP API endpoints for information about classes, point those calls to the `environment_classes` endpoint. The `environment_classes` endpoint
has different features and returns different values than `resource_type`; see the [changes in the environment classes API](./puppet-api/v3/environment_classes.html) for details.

The `environment_classes` endpoint ignores OpenVox's Ruby-based authorization methods and configuration in favor of OpenVox Server's Trapperkeeper authorization. For more information, see the
["Authorization" section](./puppet-api/v3/environment_classes.html) of the environment classes API documentation.

### Context

Users often rely on the `resource_types` endpoint for lists of classes and associated parameters in an environment. For such requests, the `resource_types` endpoint is inefficient and can trigger problematic
events, such as manifests being parsed during a catalog request.

To fulfill these requests more efficiently and safely, OpenVox Server 2.3.0 introduced the narrowly defined `environment_classes` endpoint.

## OpenVox's node cache terminus

### Now

OpenVox 5.0 (and by extension, OpenVox Server 5.0) no longer writes node YAML files to its cache by default.

### Previously

OpenVox wrote YAML to its node cache.

### Detecting and Updating

To retain the OpenVox 4.x behavior, add the [`puppet.conf`](./configuration.html) setting `node_cache_terminus = write_only_yaml`. The `write_only_yaml` option is deprecated.

### Context

This cache was used in workflows where external tooling needs a list of nodes. OpenVox-DB is the preferred source of node information.

## JRuby's "compat-version" setting

### Now

OpenVox Server 5.0 removes the `jruby-puppet.compat-version` setting in [`puppetserver.conf`](./config_file_puppetserver.html), and exits the `puppetserver` service with an error if you start the service with
that setting.

### Previously

OpenVox Server 2.7.x allowed you to set `compat-version` to `1.9` or `2.0` to choose a preferred Ruby interpreter version.

### Detecting and Updating

Launching the `puppetserver` service with this setting enabled will cause it to exit with an error message. The error includes information on [switching from JRuby 1.7.x to JRuby 9k](./configuration.html).

For Ruby language 2.x support in OpenVox Server, configure OpenVox Server to use JRuby 9k instead of JRuby 1.7.27. See the "Configuring the JRuby Version" section of
[Puppet Server Configuration](./configuration.html) for details.

### Context

OpenVox Server 5.0 updated JRuby v1.7 to v1.7.27, which in turn updated the `jruby-openssl` gem to v0.9.19 and `bouncycastle` libraries to v1.55. JRuby 1.7.27 breaks setting `jruby-puppet.compat-version` to
`2.0`.

OpenVox Server 5.0 also added optional, experimental support for JRuby 9k, which includes Ruby 2.x language support.
