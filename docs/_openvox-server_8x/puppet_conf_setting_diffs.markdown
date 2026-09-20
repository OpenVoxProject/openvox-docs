---
layout: default
title: "How OpenVox Server uses the values in puppet.conf"
---

OpenVox Server honors almost all settings in puppet.conf and should pick them up automatically. For more complete information on puppet.conf settings, see the
[Configuration Reference](/openvox/latest/configuration.html) page.

## `ca_ttl`

OpenVox Server enforces a max ttl of 50 standard years (up to 1576800000 seconds).

## `cacert`

If you enable OpenVox Server's certificate authority service, it uses the `cacert` setting in puppet.conf to determine the location of the CA certificate for such tasks as generating the CA certificate or
using the CA to sign client certificates. This is true regardless of the configuration of the `ssl-` settings in [webserver.conf](./config_file_webserver.html).

## `cacrl`

If you define `ssl-cert`, `ssl-key`, `ssl-ca-cert`, or `ssl-crl-path` in [webserver.conf](./config_file_webserver.html), OpenVox Server uses the file at `ssl-crl-path` as the CRL for authenticating
clients via SSL. If at least one of the `ssl-` settings in webserver.conf is set but `ssl-crl-path` is not set, OpenVox Server will _not_ use a CRL to validate clients via SSL.

If none of the `ssl-` settings in webserver.conf are set, OpenVox Server uses the CRL file defined for the `hostcrl` setting in puppet.conf, and not the file defined for the `cacrl` setting.

OpenVox Server keeps the `hostcrl` file in sync with the CA's CRL. When the server starts, and again each time the `cacrl` file changes (for example, when a certificate is revoked), it copies the file
for the `cacrl` setting, if one exists, over the file at the `hostcrl` location, replacing whatever is there. The web server reads the `hostcrl` file and not the `cacrl` file, so this copy is how a
revocation takes effect for client connections. The copy happens regardless of the `ssl-` settings in webserver.conf. It is skipped when `cacrl` and `hostcrl` point to the same file, and on servers
where the CA service is disabled, such as compilers. By contrast, the server copies the CA certificate to the `localcacert` location only when no file exists there.

Any CRL file updates from the OpenVox Server certificate authority---such as revocations performed via the `certificate_status` HTTP endpoint---use the `cacrl` setting in puppet.conf to determine the location
of the CRL. This is true regardless of the `ssl-` settings in webserver.conf.

Because the agent on the server host uses the same `hostcrl` file by default, this copy can break an agent that trusts a different CA. See
[When the agent on the server host trusts a different CA](#when-the-agent-on-the-server-host-trusts-a-different-ca).

## `hostcert`

If you define `ssl-cert`, `ssl-key`, `ssl-ca-cert`, or `ssl-crl-path` in [webserver.conf](./config_file_webserver.html), OpenVox Server presents the file at `ssl-cert` to clients as the server
certificate via SSL.

If at least one of the `ssl-` settings in webserver.conf is set but `ssl-cert` is not set, OpenVox Server gives an error and shuts down at startup. If none of the `ssl-` settings in webserver.conf are set,
OpenVox Server uses the file for the `hostcert` setting in puppet.conf as the server certificate during SSL negotiation.

Regardless of the configuration of the `ssl-` `webserver.conf` settings, OpenVox Server's certificate authority service, if enabled, uses the `hostcert` `puppet.conf` setting, and not the `ssl-cert` setting,
to determine the location of the server host certificate to generate.

## `hostcrl`

If you define `ssl-cert`, `ssl-key`, `ssl-ca-cert`, or `ssl-crl-path` in [webserver.conf](./config_file_webserver.html), OpenVox Server uses the file at `ssl-crl-path` as the CRL for authenticating
clients via SSL. If at least one of the `ssl-` settings in webserver.conf is set but `ssl-crl-path` is not set, OpenVox Server will _not_ use a CRL to validate clients via SSL.

If none of the `ssl-` settings in webserver.conf are set, OpenVox Server uses the CRL file defined for the `hostcrl` setting in puppet.conf, and not the file defined for the `cacrl` setting.

OpenVox Server keeps the `hostcrl` file in sync with the CA's CRL. When the server starts, and again each time the `cacrl` file changes (for example, when a certificate is revoked), it copies the file
for the `cacrl` setting, if one exists, over the file at the `hostcrl` location, replacing whatever is there. The web server reads the `hostcrl` file and not the `cacrl` file, so this copy is how a
revocation takes effect for client connections. The copy happens regardless of the `ssl-` settings in webserver.conf. It is skipped when `cacrl` and `hostcrl` point to the same file, and on servers
where the CA service is disabled, such as compilers. By contrast, the server copies the CA certificate to the `localcacert` location only when no file exists there.

Any CRL file updates from the OpenVox Server certificate authority---such as revocations performed via the `certificate_status` HTTP endpoint---use the `cacrl` setting in puppet.conf to determine the location
of the CRL. This is true regardless of the `ssl-` settings in webserver.conf.

### When the agent on the server host trusts a different CA

By default, the agent and the server on the same host share one `hostcrl` file, `$ssldir/crl.pem`. That works when the agent's certificate was issued by the CA that runs on that server. It fails when the
agent belongs to a different CA, for example while you [set up a new CA server](intermediate_ca.html) that is still managed as an agent of an existing OpenVox server.

In that case, every server start and every change to the new CA's CRL replaces the agent's CRL with one issued by the new CA, while the agent's certificate and `localcacert` file still belong to the old
CA. Agent runs, and other clients that use the same `ssldir` such as `puppetserver ca`, then fail with an error like this:

```text
certificate verify failed (unable to get certificate CRL)
```

Deleting the CRL file only helps until the next overwrite. The agent downloads a missing CRL on its next run, but otherwise refreshes it only after `crl_refresh_interval` has passed, so the problem does
not fix itself.

To stop the overwrites, give the server its own CRL location in the `[server]` section of puppet.conf, and restart OpenVox Server:

```ini
[server]
hostcrl = /etc/puppetlabs/puppetserver/ca/host_crl.pem
```

The server then copies the CA's CRL to that file, the web server reads it from there, and the agent keeps its own CRL at the default location. If you set any `ssl-` settings in webserver.conf, the web server
uses `ssl-crl-path` and not this file, as described above.

This change only prevents future overwrites. The CRL that the server already wrote is still at the agent's location, so agent runs keep failing until you replace it. After the restart, delete the agent's
CRL and run the agent, which downloads the correct CRL from its own CA:

```console
rm "$(puppet config print hostcrl --section agent)"
puppet agent --test
```

This separates only the CRL. The agent and the server on the same host still share the host certificate, private key, and CA certificate, and OpenVox Server assumes that all of them come from the same CA.
Treat a host whose agent and server belong to different CAs as a temporary state, for example during a migration, and not as a long-term configuration.

## `hostprivkey`

If you define `ssl-cert`, `ssl-key`, `ssl-ca-cert`, or `ssl-crl-path` in [webserver.conf](./config_file_webserver.html), OpenVox Server uses the file at `ssl-key` as the server private key during SSL
transactions.

If at least one of the `ssl-` settings in webserver.conf is set but `ssl-key` is not, OpenVox Server gives an error and shuts down at startup. If none of the `ssl-` settings in webserver.conf are set,
OpenVox Server uses the file for the `hostprivkey` setting in puppet.conf as the server private key during SSL negotiation.

If you enable the OpenVox Server certificate authority service, OpenVox Server uses the `hostprivkey` setting in puppet.conf to determine the location of the server host private key to generate. This is true
regardless of the configuration of the `ssl-` settings in webserver.conf.

## `localcacert`

If you define `ssl-cert`, `ssl-key`, `ssl-ca-cert`, and/or `ssl-crl-path` in [webserver.conf](./config_file_webserver.html), OpenVox Server uses the file at `ssl-ca-cert` as the CA cert store for
authenticating clients via SSL.

If at least one of the `ssl-` settings in webserver.conf is set but `ssl-ca-cert` is not set, OpenVox Server gives an error and shuts down at startup. If none of the `ssl-` settings in webserver.conf is set,
OpenVox Server uses the CA file defined for the `localcacert` setting in puppet.conf for SSL authentication.

## `masterport`

OpenVox Server does not use this setting. To set the port on which the server listens, set the `port` (unencrypted) or `ssl-port` (SSL encrypted) setting in the
[webserver.conf](./config_file_webserver.html) file.

## `ssl_client_header`

OpenVox Server honors this setting only if the `allow-header-cert-info` setting in the [`master.conf`](./config_file_master.html) file (deprecated) is set to `true`. For more information,
see the documentation on [external SSL termination](./external_ssl_termination.html).

## `ssl_client_verify_header`

OpenVox Server honors this setting only if the `allow-header-cert-info` setting in the [`master.conf`](./config_file_master.html) file (deprecated) is set to `true`. For more information,
see the documentation on [external SSL termination](./external_ssl_termination.html).

## HttpPool-Related Server Settings

## `http_proxy_host`

OpenVox Server does not currently consider this setting for any code running on the server and using the `Puppet::Network::HttpPool` module to create an HTTP client connection. This pertains, for example, to
any requests that the server would make to the `reporturl` for the `http` report processor. Note that Puppet agents do still honor this setting.

## `http_proxy_port`

OpenVox Server does not currently consider this setting for any code running on the server and using the `Puppet::Network::HttpPool` module to create an HTTP client connection. This pertains, for example, to
any requests that the server would make to the `reporturl` for the `http` report processor. Note that Puppet agents do still honor this setting.

## Overriding Puppet settings in OpenVox Server

Currently, the [`jruby-puppet` section of your `puppetserver.conf` file](./config_file_puppetserver.html) contains five settings (`master-conf-dir`, `master-code-dir`, `master-var-dir`,
`master-run-dir`, and `master-log-dir`) that allow you to override settings set in your `puppet.conf` file. On installation, these five settings will be set to the proper default values.

While you are free to change these settings at will, please note that any changes made to the `master-conf-dir` and `master-code-dir` settings absolutely MUST be made to the corresponding Puppet settings
(`confdir` and `codedir`) as well to ensure that OpenVox Server and the Puppet cli tools (such as `puppetserver ca` and `puppet module`) use the same directories. The `master-conf-dir` and `master-code-dir`
settings apply to OpenVox Server only, and will be ignored by the ruby code that runs when the Puppet CLI tools are run.

For example, say you have the `codedir` setting left unset in your `puppet.conf` file, and you change the `master-code-dir` setting to `/etc/my-puppet-code-dir`. In this case, OpenVox Server will read code
from `/etc/my-puppet-code-dir`, but the `puppet module` tool will think that your code is stored in `/etc/puppetlabs/code`.

While it is not as critical to keep `master-var-dir`, `master-run-dir`, and `master-log-dir` in sync with the `vardir`, `rundir`, and `logdir` Puppet settings, please note that this applies to these settings
as well.

Also, please note that these configuration differences also apply to the interpolation of the `confdir`, `codedir`, `vardir`, `rundir`, and `logdir` settings in your `puppet.conf` file. So, take the above
example, wherein you set `master-code-dir` to `/etc/my-puppet-code-dir`. Because the `basemodulepath` setting is by default `$codedir/modules:/opt/puppetlabs/puppet/modules`, then OpenVox Server would use
`/etc/my-puppet-code-dir/modules:/opt/puppetlabs/puppet/modules` for the value of the `basemodulepath` setting, whereas the `puppet module` tool would use
`/etc/puppetlabs/code/modules:/opt/puppetlabs/puppet/modules` for the value of the `basemodulepath` setting.
