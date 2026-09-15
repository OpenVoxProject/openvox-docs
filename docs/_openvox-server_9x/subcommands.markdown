---
layout: default
title: "Puppet Server: Subcommands"
canonical: "/puppetserver/latest/subcommands.html"
---

We've provided several CLI commands to help with debugging and exploring Puppet Server. Most of the commands are the same ones you would use in a Ruby environment --- such as `gem`, `ruby`, and `irb` --- except
they run against Puppet Server's JRuby installation and gems instead of your system Ruby.

The following subcommands are provided:

- [ca](#ca)
- [gem](#gem)
- [ruby](#ruby)
- [irb](#irb)
- [foreground](#foreground)

The format for each subcommand is:

```sh
puppetserver <subcommand> [<args>]
```

When running from source, the format is:

```sh
lein <subcommand> -c /path/to/puppetserver.conf [--] [<args>]
```

Note that if you are running from source, you need to separate flag arguments (such as `--version` or `-e`) with `--`, as shown above. Otherwise, those arguments will be applied to Leiningen instead of to
Puppet Server. This isn't necessary when running from packages (i.e., `puppetserver <subcommand>`).

## ca

## Available actions

CA subcommand usage: `puppetserver ca <action> [options]` The available actions:

- `clean`: clean files from the CA for certificates
- `generate`: create a new certificate signed by the CA
- `setup`: generate a root and intermediate signing CA for Puppet Server
- `import`: import the CA's key, certs, and CRLs
- `list`: list all certificate requests
- `revoke`: revoke a given certificate
- `sign`: sign a given certificate

Because these commands utilize Puppet Server’s API, all except `setup` and `import` need the server to be running in order to work.

Because these commands are shipped as a gem alongside Puppet Server, it can be updated out-of-band to pick up improvements and bug fixes. To upgrade it, run this command:
`/opt/puppetlabs/puppet/bin/gem install -i /opt/puppetlabs/puppet/lib/ruby/vendor_gems puppetserver-ca`

### CA CLI authorization

Every `ca` action except `setup` and `import` talks to the CA over its HTTP API, so the certificate the command presents must be allowed by [`auth.conf`](./config_file_auth.html).

The default `auth.conf` does not name the server's certname. Instead, each CA administrative rule (`certificate_status`, `certificate_statuses`, `sign`, `sign/all`, `clean`, and `PUT` on `certificate_revocation_list`) allows any client certificate that carries the `pp_cli_auth` extension (OID `1.3.6.1.4.1.34380.1.3.39`) with the value `true`.

`puppetserver ca setup` and `puppetserver ca import` add that extension to the server's own host certificate when they generate it, and OpenVox Server does the same when it creates that certificate itself on first start. That is why the CLI works on a fresh server with no configuration. To confirm a certificate has it, run:

```sh
openssl x509 -text -noout -in "$(puppet config print hostcert)"
```

In the `X509v3 extensions` section, look for `1.3.6.1.4.1.34380.1.3.39` with the value `true`, next to the `Puppet Server Internal Certificate` comment. OpenSSL prints the numeric OID because it does not know the short name.

Two consequences follow from this:

- If the server's host certificate is replaced by any other route, for example by cleaning it and letting the agent request an ordinary certificate, the new certificate lacks the extension and every `ca` action except `setup` and `import` is refused with `403 Forbidden`.
  `puppetserver ca generate` refuses to overwrite an existing certificate or key, so follow [Regenerate the primary server's certificate](./certificate_renewal.html#regenerate-the-primary-servers-certificate), which removes the old files first and shows how to carry the subject alternative names over.
- To run `puppetserver ca` from another host, generate that host's certificate the same way: stop the server, run `puppetserver ca generate --certname <host> --ca-client` on the CA, then copy the resulting key and certificate to the host.
  A certificate with `pp_cli_auth` can list, sign, revoke, and clean any certificate the CA manages, so treat it as an administrative credential and never issue it to ordinary agents.

`--ca-client` signs the certificate offline, without the running CA service, so use it only while OpenVox Server is stopped. This offline path is the only way to put the extension in a certificate. The CA refuses any CSR that requests `pp_cli_auth`, even when `allow-authorization-extensions` is enabled, so it cannot be obtained through `csr_attributes.yaml` and a normal signing.

### Signing certs with SANs or auth extensions

With the removal of `puppet cert sign`, it's possible for Puppet Server’s CA API to sign certificates with subject alternative names or auth extensions, which was previously completely disallowed. This is
disabled by default for security reasons, but you can turn it on by setting `allow-subject-alt-names` or `allow-authorization-extensions` to true in the `certificate-authority` section of Puppet Server’s config
(usually located in `ca.conf`). After these have been configured, you can use `puppetserver ca sign --certname <name>` to sign certificates with these additions.

## gem

Installs and manages gems that are isolated from system Ruby and are accessible only to Puppet Server. This is a simple wrapper around the standard Ruby `gem`, so all of the usual arguments and flags should
work as expected.

Examples:

```sh
puppetserver gem install pry --no-ri --no-rdoc
```

```sh
lein gem -c /path/to/puppetserver.conf -- install pry --no-ri --no-rdoc
```

If needed, you also can use the `JAVA_ARGS_CLI` environment variable to pass along custom arguments to the Java process that the `gem` command is run within.

Example:

```sh
JAVA_ARGS_CLI=-Xmx8g puppetserver gem install pry --no-ri --no-rdoc
```

If you prefer to have the `JAVA_ARGS_CLI` option persist for multiple command executions, you could set the value in the `/etc/sysconfig/puppetserver` or `/etc/default/puppetserver` file, depending upon your OS
distribution:

```ini
JAVA_ARGS_CLI=-Xmx8g
```

With the value specified in the sysconfig or defaults file, subsequent commands would use the `JAVA_ARGS_CLI` variable automatically:

```sh
$ puppetserver gem install pry --no-ri --no-rdoc
// Would run 'gem' with a maximum Java heap of 8g
```

For more information, see [Puppet Server and Gems](./gems.html).

## ruby

Runs code in Puppet Server's JRuby interpreter. This is a simple wrapper around the standard Ruby `ruby`, so all of the usual arguments and flags should work as expected.

Useful when experimenting with gems installed via `puppetserver gem` and the Puppet and Puppet Server Ruby source code.

Examples:

```sh
puppetserver ruby -e "require 'puppet'; puts Puppet[:certname]"
```

```sh
lein ruby -c /path/to/puppetserver.conf -- -e "require 'puppet'; puts Puppet[:certname]"
```

If needed, you also can use the `JAVA_ARGS_CLI` environment variable to pass along custom arguments to the Java process that the `ruby` command is run within.

Example:

```sh
JAVA_ARGS_CLI=-Xmx8g puppetserver ruby -e "require 'puppet'; puts Puppet[:certname]"
```

If you prefer to have the `JAVA_ARGS_CLI` option persist for multiple command executions, you could set the value in the `/etc/sysconfig/puppetserver` or `/etc/default/puppetserver` file, depending upon your OS
distribution:

```ini
JAVA_ARGS_CLI=-Xmx8g
```

With the value specified in the sysconfig or defaults file, subsequent commands would use the `JAVA_ARGS_CLI` variable automatically:

```sh
$ puppetserver ruby -e "require 'puppet'; puts Puppet[:certname]"
// Would run 'ruby' with a maximum Java heap of 8g
```

## irb

Starts an interactive REPL for the JRuby that Puppet Server uses. This is a simple wrapper around the standard Ruby `irb`, so all of the usual arguments and flags should work as expected.

Like the `ruby` subcommand, this is useful for experimenting in an interactive environment with any installed gems (via `puppetserver gem`) and the Puppet and Puppet Server Ruby source code.

Examples:

```ruby
$ puppetserver irb
irb(main):001:0> require 'puppet'
=> true
irb(main):002:0> puts Puppet[:certname]
centos6-64.localdomain
=> nil
```

```sh
$ lein irb -c /path/to/puppetserver.conf -- --version
irb 0.9.6(09/06/30)
```

If needed, you also can use the `JAVA_ARGS_CLI` environment variable to pass along custom arguments to the Java process that the `irb` command is run within.

Example:

```sh
JAVA_ARGS_CLI=-Xmx8g puppetserver irb
```

If you prefer to have the `JAVA_ARGS_CLI` option persist for multiple command executions, you could set the value in the `/etc/sysconfig/puppetserver` or `/etc/default/puppetserver` file, depending upon your OS
distribution:

```ini
JAVA_ARGS_CLI=-Xmx8g
```

With the value specified in the sysconfig or defaults file, subsequent commands would use the `JAVA_ARGS_CLI` variable automatically:

```sh
$ puppetserver irb
// Would run 'irb' with a maximum Java heap of 8g
```

## foreground

Starts the Puppet Server, but doesn't background it; similar to starting the service and then tailing the log.

Accepts an optional `--debug` argument to raise the logging level to DEBUG.

Examples:

```java
$ puppetserver foreground --debug
2014-10-25 18:04:22,158 DEBUG [main] [p.t.logging] Debug logging enabled
2014-10-25 18:04:22,160 DEBUG [main] [p.t.bootstrap] Loading bootstrap config from specified path: '/etc/puppetserver/bootstrap.cfg'
2014-10-25 18:04:26,097 INFO  [main] [p.s.j.jruby-puppet-service] Initializing the JRuby service
2014-10-25 18:04:26,101 INFO  [main] [p.t.s.w.jetty-service] Initializing web server(s).
2014-10-25 18:04:26,149 DEBUG [clojure-agent-send-pool-0] [p.s.j.jruby-puppet-agents] Initializing JRubyPuppet instances with the following settings:
```
