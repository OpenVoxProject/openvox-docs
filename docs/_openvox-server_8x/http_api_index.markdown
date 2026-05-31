---
layout: default
title: "OpenVox Server HTTP API: Index"
---

OpenVox Server provides several services via HTTP API, and the OpenVox agent application uses those services to resolve a node's credentials, retrieve a configuration catalog, retrieve file data, and submit
reports.

Many of these endpoints are the same as the [OpenVox HTTP API](/openvox/latest/http_api/http_api_index.html).

## V1/V2 HTTP APIs (removed)

The V1 and V2 APIs were removed in Puppet 4.0.0. The routes that were previously under `/` or `/v2.0` can now be found under the [`/puppet/v3`](#openvox-v3-http-api) API or [`/puppet-ca/v1`](#ca-v1-http-api)
API.

## OpenVox and OpenVox CA APIs

OpenVox's HTTP API is split into two separately versioned APIs:

- An API for configuration-related services
- An API for the certificate authority (CA).

All configuration endpoints are prefixed with `/puppet`, while all CA endpoints are prefixed with `/puppet-ca`. All endpoints are explicitly versioned: the prefix is always immediately followed by a string like
`/v3` (a directory separator, the letter `v`, and the version number of the API).

### Authorization

Authorization for `/puppet` and `/puppet-ca` endpoints is controlled with [OpenVox Server's `auth.conf` authorization system](config_file_auth.html).

## OpenVox V3 HTTP API

The OpenVox agent application uses several network services to manage systems. These services are all grouped under the `/puppet` API.
Other tools can access these services and use the OpenVox Server's data for other purposes.

The V3 API contains endpoints of two types: those that are based on dispatching to OpenVox's internal "indirector" framework, and those that are not (namely the [environments endpoint](#environments-endpoint)).

Every HTTP endpoint that dispatches to the indirector follows the form `/puppet/v3/:indirection/:key?environment=:environment`, where:

- `:environment` is the name of the environment that should be in effect for the request. Not all endpoints need an environment, but the query parameter must always be specified.
- `:indirection` is the indirection to which the request is dispatched.
- `:key` is the "key" portion of the indirection call.

Using this API requires significant understanding of how OpenVox's internal services are structured, but the following documents specify what is available and how to interact with it.

### Configuration management services

The OpenVox agent application directly uses these services to manage the configuration of a node.

These endpoints accept payload formats formatted as JSON by default (MIME type of `application/json`), except for `File Content` and `File Bucket File`, which always use `application/octet-stream`.

> **Note:** Legacy PSON (MIME type of `text/pson`) is still an available format, but should be used only as a fallback for binary content.

- [Facts](http_facts.html)
- [Catalog](http_catalog.html)
- [Node](http_node.html)
- [File bucket file](http_file_bucket_file.html)
- [File content](http_file_content.html)
- [File metadata](http_file_metadata.html)
- [Report](http_report.html)

> **Note:** The [Puppet v4 catalog API](puppet-api/v4/catalog.html) is preferred for new integrations. It does
> not require facts to be submitted as part of the catalog request.

### Environments endpoint

The `/puppet/v3/environments` endpoint uses a different format than the configuration management endpoints.

The endpoint accepts only payloads formatted as JSON, and responds with JSON (MIME type of `application/json`).

- [Environments](http_environments.html)

### OpenVox Server-specific endpoints

OpenVox Server adds several unique endpoints of its own. They include these additional `/puppet/v3/` endpoints:

- [Environment classes](puppet-api/v3/environment_classes.html), at `/puppet/v3/environment_classes`
- [Environment modules](puppet-api/v3/environment_modules.html), at `/puppet/v3/environment_modules`
- [Static file content](puppet-api/v3/static_file_content.html), at `/puppet/v3/static_file_content`

It also includes these unique APIs, with endpoints containing other URL prefixes:

- [Status API](status-api/v1/services.html), at `/status/v1/services`
- [Metrics v1 (mbeans) API](metrics-api/v1/metrics_api.html), at `/metrics/v1/mbeans`
- [Metrics v2 (Jolokia) API](metrics-api/v2/metrics_api.html), at `/metrics/v2/`
- Admin API, at `/puppet-admin-api/v1/`:
  - [Environment cache](admin-api/v1/environment-cache.html), at `/puppet-admin-api/v1/environment-cache`
  - [JRuby pool](admin-api/v1/jruby-pool.html), at `/puppet-admin-api/v1/jruby-pool`

### Error responses

The `environments` endpoint responds to error conditions in a uniform manner and uses standard HTTP response codes to signify those errors.

| Request problem | HTTP API error response code |
| --------------- | ---------------------------- |
| Client submits malformed request | 400 Bad Request |
| Unauthorized client | 403 Not Authorized |
| Client uses an HTTP method not permitted for the endpoint | 405 Method Not Allowed |
| Client requests a response in a format other than JSON | 406 Unacceptable |
| Server encounters an unexpected error while handling a request | 500 Server Error |
| Server can't find an endpoint handler for an HTTP request | 404 Not Found |

Except for HEAD requests, error responses contain a body of a uniform JSON object with the following properties:

- `message`: (`String`) A human-readable message explaining the error.
- `issue_kind`: (`String`) A unique label to identify the error class.

OpenVox provides a [JSON schema for error objects](/openvox/latest/schemas/error.json). Endpoints implemented by OpenVox Server have a different error schema:

```json
{
  "msg": "",
  "kind": ""
}
```

## CA V1 HTTP API

The certificate authority (CA) API contains all of the endpoints supporting OpenVox's public key infrastructure (PKI) system.

The CA V1 endpoints share the same basic format as the OpenVox V3 API, because they are based on the interface of OpenVox's indirector-based CA.
However, OpenVox Server's CA is implemented in Clojure. Both have a different prefix and version than the V3 API.

These endpoints follow the form `/puppet-ca/v1/:indirection/:key?environment=:environment`, where:

- `:environment` is an arbitrary placeholder word, required for historical reasons. No CA endpoints actually use an environment, but the query parameter must always be specified.
- `:indirection` is the indirection to which the request is dispatched.
- `:key` is the "key" portion of the indirection call.

As with the OpenVox V3 API, using this API requires a significant amount of understanding of how OpenVox's internal services are structured.
The following documents specify what is available and how to interact with it.

### SSL certificate-related services

These endpoints accept only plain-text payload formats. Historically, OpenVox has used the MIME type `s` to mean `text/plain`. It now uses `text/plain`, but continues to accept `s` as an equivalent.

- [Certificate](ca-api/v1/http_certificate.html)
- [Certificate Signing Requests](ca-api/v1/http_certificate_request.html)
- [Certificate Status](ca-api/v1/http_certificate_status.html)
- [Certificate Revocation List](ca-api/v1/http_certificate_revocation_list.html)
- [Certificate Clean](ca-api/v1/http_certificate_clean.html)
- [Certificate Expirations](ca-api/v1/http_certificate_expirations.html)
- [Certificate Renewal](ca-api/v1/http_certificate_renewal.html)
- [Bulk Certificate Sign](ca-api/v1/http_certificate_sign.html)

## Serialization formats

OpenVox sends messages using several serialization formats. Not all REST services support all of the formats.

- [JSON](https://tools.ietf.org/html/rfc7159)
- [PSON](pson.html) (deprecated — see the PSON page for details)

`YAML` was supported in earlier versions of OpenVox, but is no longer for security reasons.
