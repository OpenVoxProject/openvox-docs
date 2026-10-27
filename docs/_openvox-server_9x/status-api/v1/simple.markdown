---
layout: default
title: "OpenVox Server: Status API: Simple"
---

[`auth.conf`]: ../../config_file_auth.html

The `simple` endpoint of OpenVox Server's Status API provides a simple
indication of whether OpenVox Server is running on a server. It's designed for
load balancers that don't support any kind of JSON parsing or parameter setting
and returns a simple string body (either the state of the server or a simple
error message) and a status code relevant to the result.

The content type for this endpoint is `text/plain; charset=utf-8`.

## `GET /status/v1/simple`

### Supported HTTP methods

GET

### Supported formats

Plain text

### Query parameters

None

### Response

The `simple` endpoint's response consists of a single word describing OpenVox Server's status:

- `running`, if and only if the OpenVox Server service is running
- `error`, if the service reports an error
- `unknown`, if the service reports an unknown state, but doesn't report an error

Requests to this endpoint return one of the following status codes:

- 200 if and only if the OpenVox Server service reports a status of running
- 503 if the service's status is unknown or error

### Example request and response for a GET request

```text
GET /status/v1/simple

HTTP/1.1 200 OK
Content-Type: application/json

running
```

### Authorization

Requests to the `simple` endpoint are authorized by the
[Trapperkeeper-based authorization process][`auth.conf`]. For more information about the supported OpenVox Server authorization processes and configuration settings, see the
[`auth.conf` documentation][`auth.conf`].

One may also restrict access to the status service by changing the
`client-auth` setting to `required` for the webserver. See
[Configuring the Webserver Service](https://github.com/openvoxproject/trapperkeeper-webserver/blob/main/doc/jetty-config.md#client-auth)
for more information on the `client-auth` setting.
