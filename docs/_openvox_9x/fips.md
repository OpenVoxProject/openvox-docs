---
layout: default
title: "Running OpenVox in FIPS mode"
---

[supported_platforms]: supported_platforms.html
[component_versions]: component_versions.html
[mirrors]: mirrors.html
[openvox_platform]: openvox_platform.html
[server_install_pre]: /openvox-server/latest/install_pre.html
[server_known_issues]: /openvox-server/latest/known_issues.html
[openvoxdb_known_issues]: /openvoxdb/latest/known_issues.html
[rhel_fips]: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/security_hardening/switching-rhel-to-fips-mode_security-hardening
[openvox_bootstrap]: https://forge.puppet.com/modules/puppet/openvox_bootstrap
[java_ks_pr]: https://github.com/puppetlabs/puppetlabs-java_ks/pull/483
[hiera_eyaml]: https://github.com/voxpupuli/hiera-eyaml
[bc_fips]: https://www.bouncycastle.org/download/bouncy-castle-java-fips/

Enterprise Linux can run in FIPS mode, where the kernel and the system crypto
policy allow only the algorithms approved by FIPS 140. OpenVox publishes a separate
set of packages for such hosts. This page explains what those packages are, how to
install them, what does not work on a FIPS host, and how to check that a host runs
the FIPS build.

> **Note:** OpenVox itself holds no FIPS 140 validation. The FIPS packages run
> OpenSSL's FIPS provider inside the agent and the Bouncy Castle FIPS libraries
> inside the JVM components. Whether a deployment meets a given compliance
> requirement is for you to assess.

## The FIPS packages

OpenVox 9 builds FIPS packages for Enterprise Linux 8, 9, and 10 on x86-64. There
are no FIPS builds for other architectures or operating systems.

| Package | FIPS build | How it differs from the `el` build |
| --- | --- | --- |
| `openvox-agent` | Yes | Bundles an OpenSSL built with its FIPS provider. The agent's Ruby, OpenFact, and `openssl` command use only FIPS algorithms. |
| `openvox-server` | Yes | Replaces the JDK's security providers with the Bouncy Castle FIPS libraries. Runs on Java 21 only. |
| `openvoxdb` | Yes | Same as `openvox-server`. |
| `openvoxdb-termini` | Yes | Server-side plugins, matched to the FIPS server. |
| `openbolt` | No | Install OpenBolt on a host that is not in FIPS mode. |

The packages live in the `redhatfips` repositories on `yum.voxpupuli.org`, next to
the `el` ones (see [Repositories and mirrors][mirrors]):

```text
yum/openvox9/redhatfips/<el version>/x86_64/
```

The release package that configures the repository is
`openvox9-release-redhatfips-<el version>.noarch.rpm`, and the package versions carry
`redhatfips` in their release tag, for example `openvox-agent-9.2.1-1.redhatfips9`
instead of `openvox-agent-9.2.1-1.el9`. The package names are the same as in the
`el` repositories, so to `dnf` the two builds are versions of one package: a host
moves from one build to the other through an ordinary upgrade or downgrade.

FIPS builds of OpenVox Server and OpenVoxDB for Enterprise Linux 10 start with
version 9.1.0. The FIPS builds of 9.0.x ship an older line of the Bouncy Castle FIPS
libraries; see the known issues for [OpenVox Server][server_known_issues] and
[OpenVoxDB][openvoxdb_known_issues].

## Installing on a FIPS host

Put the host into FIPS mode before you install OpenVox, following your
distribution's documentation (for RHEL, see
[Switching RHEL to FIPS mode][rhel_fips]). The host is in FIPS mode when
`/proc/sys/crypto/fips_enabled` contains `1`. Enabling FIPS mode after the `el`
packages are installed works too, but read
[Moving an installed agent to the FIPS build](#moving-an-installed-agent-to-the-fips-build)
first.

1. Install the `redhatfips` release package for your Enterprise Linux version:

   ```console
   sudo dnf install https://yum.voxpupuli.org/openvox9-release-redhatfips-9.noarch.rpm
   ```

   Replace `9` with `8` or `10` as needed. The package writes
   `/etc/yum.repos.d/openvox9-release.repo` pointing at the `redhatfips` repository.

2. Install the agent:

   ```console
   sudo dnf install openvox-agent
   ```

   The package's post-install script runs `openssl fipsinstall` against the bundled
   FIPS module and installs the FIPS-enabled `/opt/puppetlabs/puppet/ssl/openssl.cnf`.

3. For OpenVox Server or OpenVoxDB, install Java 21 and make sure no Java 25 is
   present:

   ```console
   sudo dnf install java-21-openjdk-headless
   sudo dnf install openvox-server
   ```

   The FIPS packages of OpenVox Server 9 and OpenVoxDB 9 run on Java 21 only,
   because the Bouncy Castle FIPS libraries are certified up to Java 21
   ([Bouncy Castle FIPS downloads][bc_fips]). The launcher the systemd unit starts
   prefers an installed Java 25, so either leave Java 25 off the host or set
   `JAVA_BIN` to the Java 21 binary in `/etc/sysconfig/puppetserver` (and
   `/etc/sysconfig/puppetdb` for OpenVoxDB). Everything else about installing the server is as
   described in [Before you install OpenVox Server][server_install_pre].

A FIPS agent works against a server that is not in FIPS mode, and a FIPS compiler
works with a primary server that is not. If you need [hiera-eyaml][hiera_eyaml] or
another Ruby `openssl` user on the server, run the primary server on a host that is
not in FIPS mode and keep the FIPS builds for agents and compilers (see
[Known limitations](#known-limitations)).

### Picking the build in your automation

- The [openvox_bootstrap][openvox_bootstrap] module's install task (1.5.0 and later)
  selects the `redhatfips` release package when the host is in FIPS mode.
- In Puppet code, the `fips_enabled` fact tells you whether a node runs in FIPS mode.
  Code that assembles a repository URL or a release package name with a fixed `el`
  installs the non-FIPS build on a FIPS host, and nothing warns about it. The `el`
  and `redhatfips` release packages share the name `openvox9-release`, so a
  `package` resource that ensures it is present does not replace one with the other.
  Check the repository file or the installed release package's version, which
  carries `redhatfips` in its release tag, and replace it when it is the wrong one.

## Known limitations

These have all been reproduced on AlmaLinux 9 in FIPS mode with OpenVox 9.1
packages.

### Ruby `openssl` is unavailable inside a FIPS server

OpenVox Server runs Puppet code in JRuby, and JRuby's `openssl` library cannot load
when the JVM's providers are the Bouncy Castle FIPS libraries. Anything that needs
Ruby `openssl` on the server fails, with hiera-eyaml the common case:

```text
cannot load (ext) (org.jruby.ext.openssl.OpenSSL)
```

The agent's Ruby decrypts the same values without trouble, so run the primary
server on a host that is not in FIPS mode and let FIPS agents and compilers talk to
it. A FIPS compiler cannot compile catalogs that read eyaml-encrypted Hiera data.

### puppetlabs-java_ks cannot import a private key

Importing a private key with the `java_ks` type fails on a FIPS agent with
`mac generation error`. The module builds a PKCS12 bundle with a MAC whose key
derivation is not available from the agent's FIPS provider. A fix is proposed
upstream in [puppetlabs-java_ks pull request 483][java_ks_pr]; until it is
released, create keystores on a host that is not in FIPS mode or with `keytool`
directly.

### SSH on a FIPS host refuses Ed25519 keys

`sshd` on a FIPS host rejects Ed25519 host and user keys. Give OpenBolt an ECDSA
or RSA key for FIPS targets. If you generate an ECDSA key for this, write it in PEM
format (`ssh-keygen -t ecdsa -m PEM`): in testing, the SSH library OpenBolt uses
failed to sign with the same key in the OpenSSH format. The same applies to anything
else that reaches the host over SSH with an Ed25519 key, such as a deploy key r10k
uses on a FIPS compiler: switch it to ECDSA or RSA, or use HTTPS.

`ssh-keyscan` run on a FIPS host exits with status 1, because its default key
exchange proposal includes the post-quantum `sntrup761x25519` exchange, which FIPS
mode rejects. Get host keys for `known_hosts` from the provider's published list
instead.

### Moving an installed agent to the FIPS build

A host that was installed with the `el` packages and then switched to FIPS mode
moves to the `redhatfips` build when you replace the release package and upgrade
`openvox-agent`. That transaction loses the agent's OpenSSL configuration: the
`redhatfips` package writes `/opt/puppetlabs/puppet/ssl/openssl.cnf` from its
post-install script without owning the file, while the `el` package owns it, so
`rpm` removes it when it cleans up the old package. The agent then runs without
the FIPS provider and nothing warns about it. After such a move, restore the file
the way the package does, then check that the agent's Ruby reports FIPS mode:

```console
cd /opt/puppetlabs/puppet/ssl && sudo cp --preserve openssl-fips.cnf openssl.cnf
/opt/puppetlabs/puppet/bin/ruby -ropenssl -e 'puts OpenSSL.fips_mode'
```

Reinstalling the agent package (`dnf reinstall openvox-agent`) has the same effect.

## Checking a host

On an agent:

```console
$ cat /proc/sys/crypto/fips_enabled
1
$ rpm -q openvox-agent
openvox-agent-9.2.1-1.redhatfips9.x86_64
$ /opt/puppetlabs/puppet/bin/ruby -ropenssl -e 'puts OpenSSL.fips_mode'
true
```

The first command says the kernel is in FIPS mode, the second that the installed
package is the FIPS build, and the third that the agent's bundled OpenSSL loaded
its FIPS provider. A host where the third prints `false` is running the `el` build
or has lost its `openssl.cnf`.

On a server or OpenVoxDB host, also check the package and the running JVM:

```console
$ rpm -q openvox-server
openvox-server-9.1.0-1.redhatfips9.noarch
$ ps -o args= -C java | tr ' ' '\n' | grep java.security
-Djava.security.properties==/opt/puppetlabs/server/data/puppetserver/java.security.fips
```

That properties file lists the Bouncy Castle FIPS providers first and replaces the
JDK's own list. The first word of the `ps` output is the JVM binary the launcher
picked; run it with `-version` and expect Java 21.

## Related pages

- [Supported platforms][supported_platforms] marks the operating systems with FIPS builds.
- [Component versions in recent releases][component_versions] lists the OpenSSL and Java versions per release.
- [Repositories and mirrors][mirrors] and [OpenVox repositories and packages][openvox_platform] describe the repository layout.
