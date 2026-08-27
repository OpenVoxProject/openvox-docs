---
layout: default
title: "OpenVox Server: Admin API: Environment Cache"
---

When using directory environments, the OpenVox Server [caches](https://docs.openvoxproject.org/openvox/latest/environments_creating.html) the data it loads from disk for each environment.
OpenVox Server adds a new endpoint to the master's HTTP API:

## `DELETE /puppet-admin-api/v1/environment-cache`

To trigger a complete invalidation of the data in this cache, make an HTTP request to this endpoint.

### Query Parameters

This endpoint accepts an optional query parameter, `environment`, whose value may be set to the name of a specific OpenVox environment. If this parameter is provided, only the specified environment will be
flushed from the cache, as opposed to all environments.

### Response

A successful request to this endpoint will return an `HTTP 204: No Content`. The response body will be empty.

### Example

```text
$ curl -i --cert $(puppet config print hostcert) --key $(puppet config print hostprivkey) --cacert $(puppet config print localcacert) -X DELETE https://$(puppet config print certname):8140/puppet-admin-api/v1/environment-cache
HTTP/1.1 204 No Content

$ curl -i --cert $(puppet config print hostcert) --key $(puppet config print hostprivkey) --cacert $(puppet config print localcacert) -X DELETE https://localhost:8140/puppet-admin-api/v1/environment-cache?environment=production
HTTP/1.1 204 No Content
```

## Relevant Configuration

Access to this endpoint is controlled by the `puppet-admin` section of `puppetserver.conf`. See [the configuration page](../../configuration.html) for more information.

In the example above, the `curl` command is using a certificate and private key. You must make sure this certificate's name is included in the `puppet-admin -> client-whitelist` setting before you can use it.
