---
layout: default
title: "OpenVox Server CA API: Bulk Certificate Sign"
---

## Bulk Certificate Sign

The `sign` endpoints allow an administrator to sign one or more pending certificate signing requests (CSRs)
in a single API call. These endpoints are alternatives to using the `puppetserver ca sign` CLI command.

Both endpoints require a client certificate with the `pp_cli_auth: "true"` extension.

## Sign specific certificates

Sign one or more pending CSRs by certname.

```text
POST /puppet-ca/v1/sign
Content-Type: application/json
```

The request body must contain a `certnames` array listing the certnames to sign.

### Supported HTTP Methods

POST

### Supported Response Formats

`application/json`

### Parameters

None (certnames are provided in the request body)

### Access

Requires a client certificate with the `pp_cli_auth: "true"` certificate extension. Access is controlled by
OpenVox Server's `ca.conf` authorization configuration.

### Example

#### Request

```text
POST /puppet-ca/v1/sign
Content-Type: application/json

{"certnames": ["one.example.com", "nocsrone.example.com"]}
```

#### Response

```text
HTTP/1.1 200 OK
Content-Type: application/json

{
  "signed": ["one.example.com"],
  "no-csr": ["nocsrone.example.com"],
  "signing-errors": []
}
```

The response always contains three arrays:

- `signed` — certnames whose CSRs were successfully signed.
- `no-csr` — certnames for which no pending CSR was found.
- `signing-errors` — certnames whose CSRs failed one or more validation checks. Checks include
  subject alternative name allowance, authorization extension allowance, unrecognized extensions,
  and signature validity. Example:

```text
HTTP/1.1 200 OK
Content-Type: application/json

{
  "signed": [],
  "no-csr": [],
  "signing-errors": ["badextension.example.com", "invalidsignature.example.com"]
}
```

A `200 OK` is returned even if some certnames appear in `no-csr` or `signing-errors`. A `422 Unprocessable
Entity` is returned if the request body does not conform to the expected schema (for example, if `certnames`
contains non-string values):

```text
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/json

{"kind":"schema-violation","submitted":[42],"error":"[(not (instance? java.lang.String 42))]"}
```

## Sign all pending certificates

Sign all currently pending CSRs at once. The server automatically discovers all pending CSRs in the
configured CSR directory — no request body is needed.

### Supported HTTP Methods

POST

### Supported Response Formats

`application/json`

### Parameters

None

### Access

Requires a client certificate with the `pp_cli_auth: "true"` certificate extension. Access is controlled by
OpenVox Server's `ca.conf` authorization configuration.

### Example

#### Request

```text
POST /puppet-ca/v1/sign/all
```

#### Response

```text
HTTP/1.1 200 OK
Content-Type: application/json

{
  "signed": ["one.example.com", "two.example.com"],
  "no-csr": [],
  "signing-errors": []
}
```

If there are no pending CSRs, the `signed` array is empty and the response is still `200 OK`.
