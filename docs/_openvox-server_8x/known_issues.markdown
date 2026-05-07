---
layout: default
title: "OpenVox Server: Known Issues"
---

For a list of all known issues, visit the [OpenVox Server issue tracker](https://github.com/OpenVoxProject/openvox-server/issues).

## Potential JAVA ARGS settings

If you're working outside of lab environment, increase `ReservedCodeCache` to `512m` under normal load. If you're working with 6-12 JRuby instances (or a `max-requests-per-instance` value significantly less
than 100k), run with a `ReservedCodeCache` of 1G. Twelve or more JRuby instances in a single server might require 2G or more.

Similar caveats regarding scaling `ReservedCodeCache` might apply if users are managing `MaxMetaspace`.

## `tmp` directory mounted `noexec`

In some cases (especially for RHEL installations) if the `/tmp` directory is mounted as `noexec`, OpenVox Server may fail to run correctly, and you may see an error in the OpenVox Server logs similar to the
following:

```text
Nov 12 17:46:12 fqdn.com java[56495]: Failed to load feature test for posix: can't find user for 0
Nov 12 17:46:12 fqdn.com java[56495]: Cannot run on Microsoft Windows without the win32-process, win32-dir and win32-service gems: Win32API only supported on win32
Nov 12 17:46:12 fqdn.com java[56495]: Puppet::Error: Cannot determine basic system flavour
```

This is caused by the fact that JRuby contains some embedded files which need to be copied somewhere on the filesystem before they can be executed
([see this JRuby issue](https://github.com/jruby/jruby/issues/2186)). To work around this issue, you can either mount the `/tmp` directory without `noexec`, or you can choose a different directory to use as the
temporary directory for the OpenVox Server process.

Either way, you'll need to set the permissions of the directory to `1777`. This allows the OpenVox Server JRuby process to write a file to `/tmp` and then execute it. If permissions are set incorrectly, you'll
get a massive stack trace without much useful information in it.

To use a different temporary directory, you can set the following JVM property:

```text
-Djava.io.tmpdir=/some/other/temporary/directory
```

When OpenVox Server is installed from packages, add this property to the `JAVA_ARGS` and `JAVA_ARGS_CLI` variables defined in either `/etc/sysconfig/puppetserver` or `/etc/default/puppetserver`, depending on
your distribution. Invocations of the `gem`, `ruby`, and `irb` subcommands use the updated `JAVA_ARGS_CLI` on their next invocation. The service will need to be restarted in order to re-read the `JAVA_ARGS`
variable.

## OpenVox Server fails to connect to load-balanced servers with different SSL certificates

Intermittent SSL connection failures have been seen when OpenVox Server tries to make SSL requests to servers via the same virtual IP address where the servers present different certificates during the SSL
handshake. For more information, see [this page](./ssl_server_certificate_change_and_virtual_ips.html).
