---
layout: default
title: "OpenVox Server: Puppet API: Environment Transports"
---

[HTTP API]: /openvox/latest/http_api/http_api_index.html
[environment cache API]: ../../admin-api/v1/environment-cache.html
[environment classes API]: ./environment_classes.html
[transports schema]: ./environment_transports.json
[`auth.conf` documentation]: ../../config_file_auth.html

The environment transports API returns a JSON object representing the requested environment and schemas for all available [HTTP API][] endpoints.
The endpoint follows all conventions set by the [environment classes API][] including request format, etag validation with expiration managed by the [environment cache API][], and errors.

## `GET /puppet/v3/environment_transports?environment=<environment>`

### Query Parameters

#### `environment` (required)

The name of the environment to query for available device transport schemas.

### Schema

The transports endpoint response body conforms to the [transports schema][].

### Authorization

All requests made to the environment transports API are authorized using the Trapperkeeper-based `auth.conf`.
For more information about the OpenVox Server authorization process and configuration settings, see the [`auth.conf` documentation][].
