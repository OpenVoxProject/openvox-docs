---
layout: default
title: "Renewing and regenerating certificates"
---

Every certificate in an OpenVox deployment has a fixed lifetime. By default, certificates that the running CA signs for agents and compilers are valid for 5 years, while the CA certificate itself is valid for 15 years. When a certificate expires, TLS connections start failing with errors such as `certificate verify failed` or `certificate has expired`, and agent runs stop working.

This page explains how to find out which certificate expired, how to replace an expired host or agent certificate, how to turn on automatic renewal to prevent future expirations, and how to extend an expired CA certificate without reissuing every agent certificate.

> **Note:** Both lifetimes are controlled by the same setting, whose name is misleading. The [`ca_ttl`](/openvox/latest/configuration.html#ca_ttl) setting in `puppet.conf` (default `5y`) controls the lifetime of certificates the CA *signs*, not the CA certificate itself.
> The CA certificate's 15-year lifetime is a built-in fallback that `puppetserver ca setup` uses when `ca_ttl` is not set in `puppet.conf`; if you set `ca_ttl` before running setup, the CA certificate uses that value instead.
> The same fallback applies to any certificate the `puppetserver ca` CLI creates while the server is stopped, including the primary server's own certificate, so it can outlive the 5-year agent certificates.

## Find out which certificate expired

Check the expiration dates with `openssl`. On the primary server:

```console
openssl x509 -enddate -noout -in "$(puppet config print hostcert)"
openssl x509 -enddate -noout -in /etc/puppetlabs/puppetserver/ca/ca_crt.pem
```

On an agent, check its own certificate and its copy of the CA certificate:

```console
openssl x509 -enddate -noout -in "$(puppet config print hostcert)"
openssl x509 -enddate -noout -in "$(puppet config print localcacert)"
```

To inspect a certificate in full (subject, issuer, alt names, and validity), use `openssl x509 -in <cert>.pem -text -noout`. If `ca_crt.pem` contains a bundle of several certificates (the default layout uses an intermediate signing cert plus a root cert), `openssl x509` only shows the first one; use `openssl storeutl -noout -text ca_crt.pem` to print them all.

With default settings, a certificate that expired 5 years after it was issued is a host certificate, and the CA certificate is still valid: the CA is not due to expire until 15 years after it was created.

## Regenerate the primary server's certificate

Use this procedure when the expired certificate is the primary server's own host certificate and the server is also the CA. The new certificate is signed by the existing CA, so agents are unaffected and nothing needs to change on other nodes.

1. Stop OpenVox Server and back up the SSL directory:

   ```console
   systemctl stop puppetserver
   cp -a /etc/puppetlabs/puppet/ssl /etc/puppetlabs/puppet/ssl.bak
   ```

1. Remove the expired certificate and its keys, and the CA's copy of the signed certificate:

   ```console
   CERTNAME="$(puppet config print certname)"
   rm /etc/puppetlabs/puppet/ssl/certs/"$CERTNAME".pem
   rm /etc/puppetlabs/puppet/ssl/private_keys/"$CERTNAME".pem
   rm /etc/puppetlabs/puppet/ssl/public_keys/"$CERTNAME".pem
   rm /etc/puppetlabs/puppetserver/ca/signed/"$CERTNAME".pem
   ```

1. Generate a new certificate. The `--ca-client` flag makes this work offline, signing directly with the CA's key while the server is stopped:

   ```console
   puppetserver ca generate --certname "$CERTNAME" --ca-client
   ```

   The original certificate usually contains subject alternative names, and `puppetserver ca generate` does not carry them over. Check the backed-up certificate with `openssl x509 -text -noout` and pass every name agents use, such as a load balancer name, a CNAME, or a `puppet` DNS alias, with `--subject-alt-names`.
   A certificate created at setup time includes `DNS:puppet` by default, so regenerating without the flag drops that name and agents that connect to the server as `puppet` reject the new certificate.
   Don't rely on `puppet config print dns_alt_names` here: the setting is usually empty even when the certificate has alternative names.

   If the command reports that it could not determine whether Puppet Server is online (for example, when the `server` hostname does not resolve), confirm that the service is stopped and rerun with `--force`.

1. Start OpenVox Server and verify the new certificate:

   ```console
   systemctl start puppetserver
   openssl x509 -enddate -noout -in "$(puppet config print hostcert)"
   ```

   Then run `puppet agent -t` on an agent to confirm that agents can connect.

If OpenVoxDB runs on the same host, it keeps its own copies of the certificate, key, and CA certificate in `/etc/puppetlabs/puppetdb/ssl/`. Refresh them and restart OpenVoxDB:

```console
puppetdb ssl-setup -f
systemctl restart puppetdb
```

## Regenerate an agent certificate

Use this procedure when an agent's certificate has expired, or when a compiler's certificate has expired and the CA runs on a different server. An expired client certificate can't authenticate, so the agent needs a new one signed by the CA.

1. On the CA server, revoke and remove the old certificate:

   ```console
   puppetserver ca clean --certname <agent-certname>
   ```

1. On the agent, delete the expired certificate and key:

   ```console
   puppet ssl clean
   ```

1. On the agent, request a new certificate:

   ```console
   puppet ssl bootstrap
   ```

   This submits a new certificate signing request, then waits and retries every 2 minutes until the certificate is signed. Leave it running while you sign the request in the next step; it downloads the certificate on its next retry.
   To submit the request without waiting instead, run `puppet ssl bootstrap --waitforcert 0`; it submits the request and then exits with an error noting the certificate has not been signed yet, which is expected. Sign the request, then run the command again to download the certificate. A regular `puppet agent -t` run submits the same request.

1. If you don't use autosigning, sign the request from a session on the CA server:

   ```console
   puppetserver ca sign --certname <agent-certname>
   ```

If the certificate needs subject alternative names, the CA must have `allow-subject-alt-names: true` in the `certificate-authority` section of [`ca.conf`](config_file_ca.html), and the agent must request them, for example with `puppet ssl bootstrap --dns_alt_names <name1>,<name2>`.

For a compiler, stop OpenVox Server on the compiler before cleaning its certificate and start it again after the new certificate is in place. If OpenVoxDB shares the host, refresh its certificate copies as shown in the previous section.

## Turn on automatic renewal

OpenVox Server supports automatic certificate renewal, which prevents host certificates from ever reaching their expiration date. It is off by default.
The packaged [`ca.conf`](config_file_ca.html) already contains the settings in its `certificate-authority` section; set `allow-auto-renewal` to `true` and restart OpenVox Server:

```text
certificate-authority: {
    allow-auto-renewal: true
    auto-renewal-cert-ttl: "60d"
}
```

With auto-renewal enabled, the CA issues certificates to renewal-capable agents with the shorter `auto-renewal-cert-ttl` lifetime instead of the `ca_ttl` value.
The packaged configuration sets `auto-renewal-cert-ttl` to 60 days; when the setting is absent, the built-in default is 90 days.
All OpenVox agents support renewal: when an agent's certificate is within `hostcert_renewal_interval` (30 days by default) of expiring, the agent requests a renewed certificate during its regular run and switches to it transparently, using the [certificate renewal endpoint](ca-api/v1/http_certificate_renewal.html).

You can also renew a certificate on demand by running `puppet ssl renew_cert` on the agent. It uses the same renewal endpoint and works on any still-valid certificate once renewal is enabled, including certificates issued before you enabled it, and replaces the certificate with one that has the `auto-renewal-cert-ttl` lifetime.
Pass `--if-expiring-in <duration>` (for example `30d`) to renew only when the certificate is close to expiry.
If `allow-auto-renewal` is not enabled on the CA, the command does nothing and still exits successfully, so check the certificate's expiration date afterward to confirm the renewal happened.

Renewal authenticates with the agent's current certificate, so it only works while that certificate is still valid. It does not work for a certificate that has already expired: use the regeneration procedures above first, then enable auto-renewal.

## Extend an expired CA certificate

An expired CA certificate does not require rebuilding the CA and reissuing every certificate in the deployment. Because every host certificate was signed by the CA's private key, re-signing the CA certificate with the same key and subject gives it a new validity period while existing host certificates remain valid.
Only the CA certificate file changes, and you then distribute it to the rest of the deployment.

The [`puppetlabs/ca_extend`](https://forge.puppet.com/modules/puppetlabs/ca_extend) module automates this procedure and works with open source deployments.
Its `extend_ca_cert` plan re-signs the CA certificate on the primary server (pass `regen_primary_cert=true` if the server's own host certificate has also expired) and repairs an expired CRL along the way, and its `upload_ca_cert` plan distributes the refreshed certificate to agents.
If you can run OpenBolt against your infrastructure, use the module. The manual procedure below performs the same steps.

> **Warning:** A mistake here can break authentication for the whole deployment. Back up the CA directory (`/etc/puppetlabs/puppetserver/ca`) before you start, and test the procedure in a test environment first if you can.
> If your CA uses the default intermediate layout, `ca_crt.pem` is a bundle of the signing certificate and the root certificate. The same re-signing technique applies to each certificate in the bundle, but you must re-sign the root with the root's key (`root_key.pem`) and the intermediate with the root as issuer, then rebuild the bundle in the same order.

To extend a CA with a single self-signed certificate manually, on the CA server:

1. Confirm the CA key matches the CA certificate; the two digests must be identical:

   ```console
   cd /etc/puppetlabs/puppetserver/ca
   openssl rsa -noout -modulus -in ca_key.pem | openssl md5
   openssl x509 -noout -modulus -in ca_crt.pem | openssl md5
   ```

1. Back up the certificate, then turn it into a new CSR signed by the same key:

   ```console
   cp -p ca_crt.pem ca_crt.pem.bak
   openssl x509 -x509toreq -in ca_crt.pem -signkey ca_key.pem -out ca_csr.pem
   ```

1. Re-sign it with the CA extensions and a new validity period (15 years here):

   ```console
   cat > extension.cnf <<EOF
   [CA_extensions]
   basicConstraints = critical,CA:TRUE
   keyUsage = critical,keyCertSign,cRLSign
   subjectKeyIdentifier = hash
   EOF
   openssl x509 -req -days 5475 -in ca_csr.pem -signkey ca_key.pem -out ca_crt.pem -extfile extension.cnf -extensions CA_extensions
   openssl x509 -enddate -noout -in ca_crt.pem
   chown puppet:puppet ca_crt.pem
   ```

1. Copy the refreshed CA certificate to the server's agent-side location and restart the service:

   ```console
   cp -p ca_crt.pem "$(puppet config print localcacert)"
   systemctl restart puppetserver
   ```

   If OpenVoxDB shares the host, refresh its copies and restart it as well:

   ```console
   puppetdb ssl-setup -f
   systemctl restart puppetdb
   ```

1. Distribute the refreshed CA certificate to every agent. Deleting the agent's copy is enough, because downloading the CA certificate doesn't require a valid client certificate, so the next run fetches the new one:

   ```console
   rm "$(puppet config print localcacert)"
   puppet agent -t
   ```

If the server's own host certificate expired at the same time, regenerate it as described in [Regenerate the primary server's certificate](#regenerate-the-primary-servers-certificate). Check the CRL too: if it has also expired, see [CRL refresh](crl_refresh.html).

Extending the CA only works while you still have its private key. If `ca_key.pem` is lost or compromised, you must instead regenerate the CA and every certificate in the deployment:
stop all services, move aside `/etc/puppetlabs/puppet/ssl` and `/etc/puppetlabs/puppetserver/ca`, run `puppetserver ca setup`, and then reissue certificates for the server, OpenVoxDB, and every agent as described in the sections above.

This procedure is adapted from a [community walkthrough by bastelfreak](https://gist.github.com/bastelfreak/ed874f03e7849d35eb8ec832a58da8f3).

## Related pages

- [Intermediate CA](intermediate_ca.html): running the OpenVox CA under an external root
- [CA service configuration: ca.conf](config_file_ca.html)
- [CRL refresh](crl_refresh.html)
- [`ca_ttl` in the configuration reference](/openvox/latest/configuration.html#ca_ttl)
