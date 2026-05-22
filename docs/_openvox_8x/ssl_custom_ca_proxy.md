---
layout: default
title: "SSL configuration: Adding a custom CA for HTTPS-inspecting proxies"
---

Some network environments use HTTPS-inspecting proxies (such as Squid with SSL Bump) that
re-sign outbound TLS connections using a local CA. OpenVox's Ruby runtime uses its own
bundled CA certificate store rather than the system trust store, so the proxy CA must be
added explicitly before OpenVox will trust connections the proxy intercepts.

Common symptoms: `gem install` or module downloads (`puppet module install`) fail with
certificate verification errors even though the system CA trust store already includes the
proxy CA.

## How OpenVox validates outbound TLS

OpenVox ships its own Ruby runtime with a vendored CA bundle compiled in at
`/opt/puppetlabs/puppet/ssl/cert.pem`. This path is OpenVox's `OpenSSL::X509::DEFAULT_CERT_FILE`
and is what Ruby uses — not the OS trust store — when validating TLS certificates for
outbound connections such as gem downloads and `puppet module install`.

## Quick fix: append the CA to the bundle

Appending your proxy CA to `cert.pem` works immediately and requires no additional
configuration:

```console
cat /path/to/proxy-ca.pem >> /opt/puppetlabs/puppet/ssl/cert.pem
```

The downside is that `cert.pem` is owned by the `openvox-agent` package and may be
overwritten during upgrades, removing your CA and breaking the proxy again.

## Persistent fix: `ssl_trust_store` (module downloads only)

For `puppet module install` and https file sources, the cleanest option is the
`ssl_trust_store` setting in `puppet.conf`. OpenVox loads this file as an additional trust
store on top of the built-in bundle, so your proxy CA survives upgrades and no environment
variables are required:

```console
puppet config set ssl_trust_store /etc/ssl/certs/proxy-ca.pem
```

**Important:** `ssl_trust_store` only applies to Puppet's own outbound HTTPS requests. It
does not affect gem installs performed via the `puppet_gem` package provider, because those
run `gem` as a subprocess that does not read `puppet.conf`. Use the `SSL_CERT_FILE` approach
below if you also need gem installs to work.

## Persistent fix: `SSL_CERT_FILE` pointing at a merged bundle

The `SSL_CERT_FILE` environment variable overrides OpenSSL's default cert path and works
for both `puppet module install` and gem installs. Create a merged bundle that combines the
original Mozilla certs with your proxy CA:

```console
cat /opt/puppetlabs/puppet/ssl/cert.pem /path/to/proxy-ca.pem \
  > /etc/ssl/certs/puppet-custom-bundle.pem
```

**Make it permanent for the Puppet agent service** by adding the variable to the service
environment. On systemd systems, create a drop-in:

```console
mkdir -p /etc/systemd/system/puppet.service.d
cat > /etc/systemd/system/puppet.service.d/ssl_cert_file.conf <<'EOF'
[Service]
Environment=SSL_CERT_FILE=/etc/ssl/certs/puppet-custom-bundle.pem
EOF
systemctl daemon-reload
systemctl restart puppet
```

For one-off commands, export the variable in the same shell:

```console
SSL_CERT_FILE=/etc/ssl/certs/puppet-custom-bundle.pem puppet agent -t
```

## Managing with Puppet

Use [puppetlabs/concat](https://forge.puppet.com/modules/puppetlabs/concat) to assemble
and maintain the merged bundle. The `file:///` source scheme reads `cert.pem` directly from
the local filesystem at catalog apply time, so the bundle automatically picks up the fresh
Mozilla certs after an `openvox-agent` upgrade:

```puppet
concat { '/etc/ssl/certs/puppet-custom-bundle.pem':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  mode   => '0644',
}

concat::fragment { 'openvox-mozilla-bundle':
  target => '/etc/ssl/certs/puppet-custom-bundle.pem',
  source => 'file:///opt/puppetlabs/puppet/ssl/cert.pem',
  order  => '01',
}

concat::fragment { 'proxy-ca':
  target  => '/etc/ssl/certs/puppet-custom-bundle.pem',
  content => lookup('profile::proxy_ca_cert'),
  order   => '02',
}

file { '/etc/systemd/system/puppet.service.d/ssl_cert_file.conf':
  ensure  => file,
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  content => "[Service]\nEnvironment=SSL_CERT_FILE=/etc/ssl/certs/puppet-custom-bundle.pem\n",
  notify  => Exec['systemd-daemon-reload'],
}

exec { 'systemd-daemon-reload':
  command     => '/bin/systemctl daemon-reload',
  refreshonly => true,
}
```

Store the proxy CA certificate as a multiline string in Hiera:

```yaml
profile::proxy_ca_cert: |
  -----BEGIN CERTIFICATE-----
  ...
  -----END CERTIFICATE-----
```

Because `concat::fragment` reads `cert.pem` on every Puppet run, the merged bundle stays
current after upgrades with no additional steps.

## Verifying the configuration

Confirm Ruby can reach an intercepted host:

```console
/opt/puppetlabs/puppet/bin/ruby -rnet/http -ruri \
  -e 'Net::HTTP.get(URI("https://forgeapi.puppet.com")); puts "OK"'
```

A successful response prints `OK`. A certificate verification error means the proxy CA is
still not trusted by OpenVox's Ruby environment.
