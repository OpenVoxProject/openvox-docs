---
layout: default
title: "OpenVox Server CA API: Certificate Expirations"
---

## Certificate Expirations

The `expirations` endpoint returns the `not-after` date for every certificate in the CA bundle and the
`next-update` date of every CRL in the chain. This is useful for monitoring CA infrastructure health and
alerting before CA certificate or CRL expiration causes service disruption.

## Get

Retrieve expiration information for the CA bundle and CRL chain.

    GET /puppet-ca/v1/expirations

### Supported HTTP Methods

GET

### Supported Response Formats

`application/json`

### Parameters

None

### Access

Any client with a certificate signed by the CA may access this endpoint. Access is controlled by OpenVox
Server's `ca.conf` authorization configuration.

### Example Response

    GET /puppet-ca/v1/expirations

    HTTP/1.1 200 OK
    Content-Type: application/json

    {
      "ca-certs": {
        "Puppet CA: ca.example.com": "2041-05-15T11:22:16UTC",
        "Puppet Root CA: a3f8c1d74b2e05": "2041-05-15T11:22:14UTC"
      },
      "crls": {
        "Puppet CA: ca.example.com": "2031-05-26T14:36:05UTC",
        "Puppet Root CA: a3f8c1d74b2e05": "2041-05-15T11:22:14UTC"
      }
    }

The response contains two top-level keys:

- `ca-certs` — maps each CA certificate's subject name to its `not-after` date.
- `crls` — maps each CRL issuer's subject name to its `next-update` date.

Timestamps are in UTC. The subject name keys reflect the CN of each certificate in the CA bundle.
Deployments using an intermediate CA will have one entry per CA in the chain, as shown above.
