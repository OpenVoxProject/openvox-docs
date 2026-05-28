---
layout: default
title: "OpenVox Server CA API: Certificate Renewal"
---

## Certificate Renewal

The `certificate_renewal` endpoint allows an OpenVox agent to automatically renew its own certificate without
requiring an administrator to sign a new CSR. The agent makes the request authenticated with its current
certificate (via mutual TLS), and if auto-renewal is enabled and the certificate was signed by this CA, a new
certificate is returned.

> **Note:** This endpoint is disabled by default. It requires `certificate-authority.allow-auto-renewal: true`
> in OpenVox Server's CA configuration before it will return anything other than 404.

## Renew

Submit a certificate renewal request.

    POST /puppet-ca/v1/certificate_renewal

The request has no body. OpenVox Server identifies the certificate to renew from the TLS client certificate
presented during the connection. If `allow-header-cert-info` is enabled in the CA settings, the certificate
may instead be provided via the `X-Client-Cert` HTTP header.

### Supported HTTP Methods

POST

### Supported Response Formats

`text/plain` (PEM-encoded signed certificate)

### Parameters

None

### Configuration

Two settings in the `certificate-authority` section of OpenVox Server's configuration control this endpoint:

- `allow-auto-renewal` — must be `true` to enable the endpoint. Defaults to `false`.
- `auto-renewal-cert-ttl` — sets the validity period of the renewed certificate. Defaults to `90d`.

### Access

Any client with a certificate signed by the CA may access this endpoint. Access is controlled by OpenVox
Server's `ca.conf` authorization configuration. The endpoint should never be used unauthenticated, as it
requires a valid client certificate to identify the certificate to renew.

### Responses

#### Renewal successful

    POST /puppet-ca/v1/certificate_renewal

    HTTP/1.1 200 OK
    Content-Type: text/plain

    -----BEGIN CERTIFICATE-----
    ... (new signed certificate) ...
    -----END CERTIFICATE-----

The renewed certificate is valid for the period configured in `auto-renewal-cert-ttl`.

#### Auto-renewal disabled

    HTTP/1.1 404 Not Found

`certificate-authority.allow-auto-renewal` is not enabled.

#### Certificate not recognized

    HTTP/1.1 403 Forbidden
    Content-Type: text/plain

    Certificate present, but does not match signature

The certificate presented was not signed by this CA.

#### No valid certificate in request

    HTTP/1.1 400 Bad Request
    Content-Type: text/plain

    No valid certificate found in renewal request

No client certificate was found in the TLS session or the `X-Client-Cert` header.
