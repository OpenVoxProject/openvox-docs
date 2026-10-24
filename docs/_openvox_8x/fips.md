---
layout: default
title: "Running OpenVox in FIPS mode"
---

[supported_platforms]: supported_platforms.html
[component_versions]: component_versions.html
[mirrors]: mirrors.html
[openvox_platform]: openvox_platform.html
[server_install_pre]: /openvox-server/8.x/install_pre.html
[rhel_fips]: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/security_hardening/switching-rhel-to-fips-mode_security-hardening
[openvox_bootstrap]: https://forge.puppet.com/modules/puppet/openvox_bootstrap
[java_ks_pr]: https://github.com/puppetlabs/puppetlabs-java_ks/pull/483
[hiera_eyaml]: https://github.com/voxpupuli/hiera-eyaml
[bc_fips]: https://www.bouncycastle.org/download/bouncy-castle-java-fips/
[fips_140]: https://csrc.nist.gov/pubs/fips/140-3/final

Enterprise Linux can run in FIPS mode, where the kernel and the system crypto
policy allow only the algorithms approved under [FIPS 140][fips_140], the Federal
Information Processing Standard for cryptographic modules. OpenVox publishes a
separate set of packages for such hosts. This page explains what those packages are, how to
install them, what does not work on a FIPS host, and how to check that a host runs
the FIPS build.

> **Note:** OpenVox itself holds no FIPS 140 validation. The FIPS packages run
> OpenSSL's FIPS provider inside the agent and the Bouncy Castle FIPS libraries
> inside the JVM components. Whether a deployment meets a given compliance
> requirement is for you to assess.

## The FIPS packages

OpenVox 8 builds FIPS packages for Enterprise Linux 8 and 9 on x86-64. There
are no FIPS builds for other architectures or operating systems.

| Package | FIPS build |
| --- | --- |
| `openvox-agent` | Bundles an OpenSSL built with its FIPS provider. The agent's Ruby, OpenFact, and `openssl` command use only FIPS algorithms. |
| `openvox-server` | Replaces the JDK's security providers with the Bouncy Castle FIPS libraries. |
| `openvoxdb` | Same as `openvox-server`. |
| `openvoxdb-termini` | Server-side plugins, matched to the FIPS server. |
| `openbolt` | None. Install OpenBolt on a host that is not in FIPS mode. |

The packages live in the `redhatfips` repositories on `yum.voxpupuli.org`, next to
the `el` ones (see [Repositories and mirrors][mirrors]):

```text
yum/openvox8/redhatfips/<el version>/x86_64/
```

The release package that configures the repository is
`openvox8-release-redhatfips-<el version>.noarch.rpm`, and the package versions carry
`redhatfips` in their release tag, for example `openvox-agent-8.31.1-1.redhatfips9`
instead of `openvox-agent-8.31.1-1.el9`. The package names are the same as in the
`el` repositories, so to `dnf` the two builds are versions of one package: a host
moves from one build to the other through an ordinary upgrade or downgrade.

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
   sudo dnf install \
     https://yum.voxpupuli.org/openvox8-release-redhatfips-9.noarch.rpm
   ```

   Replace `9` with `8` as needed. The package writes
   `/etc/yum.repos.d/openvox8-release.repo` pointing at the `redhatfips` repository.

2. Install the agent:

   ```console
   sudo dnf install openvox-agent
   ```

   The package's post-install script runs `openssl fipsinstall` against the bundled
   FIPS module and installs the FIPS-enabled `/opt/puppetlabs/puppet/ssl/openssl.cnf`.

3. For OpenVox Server or OpenVoxDB, install a supported Java first, then the
   package:

   ```console
   sudo dnf install java-17-openjdk-headless
   sudo dnf install openvox-server
   ```

   The FIPS packages of OpenVox Server 8 and OpenVoxDB 8 depend on Java 17
   (`jre-17-headless`), the same as the `el` packages, and the Bouncy Castle FIPS
   1.x libraries they bundle are certified up to Java 17
   ([Bouncy Castle FIPS downloads][bc_fips]), so run them on Java 17. Everything
   else about installing the server is as described in
   [Before you install OpenVox Server][server_install_pre].

A FIPS agent works against a server that is not in FIPS mode, agents that are not
in FIPS mode get their catalogs from a FIPS server, and a FIPS compiler works with a
primary server that is not. If you need [hiera-eyaml][hiera_eyaml] or
another Ruby `openssl` user on the server, run every server that compiles catalogs
from that data, the primary and any compiler, on hosts that are not in FIPS mode,
and keep the FIPS builds for agents (see [Known limitations](#known-limitations)).

### Picking the build in your automation

- The [openvox_bootstrap][openvox_bootstrap] module's install task (1.5.0 and later)
  selects the `redhatfips` release package when the host is in FIPS mode.
- In Puppet code, the `fips_enabled` fact tells you whether a node runs in FIPS mode.
  Code that assembles a repository URL or a release package name with a fixed `el`
  installs the non-FIPS build on a FIPS host, and nothing warns about it. The `el`
  and `redhatfips` release packages share the name `openvox8-release`, so a
  `package` resource that ensures it is present does not replace one with the other.
  Check the repository file or the installed release package's version, which
  carries `redhatfips` in its release tag, and replace it when it is the wrong one.

## Known limitations

These have all been reproduced on AlmaLinux 9 in FIPS mode with OpenVox 8.31
agents and an OpenVox Server 9.1 FIPS build; the OpenVox Server 8 FIPS build uses
the same Bouncy Castle FIPS providers.

### Ruby `openssl` is unavailable inside a FIPS server

OpenVox Server runs Puppet code in JRuby, and JRuby's `openssl` library cannot load
when the JVM's providers are the Bouncy Castle FIPS libraries. Anything that needs
Ruby `openssl` on the server fails, with hiera-eyaml the common case:

```text
cannot load (ext) (org.jruby.ext.openssl.OpenSSL)
```

Hiera data is decrypted on the server that compiles the catalog, so this applies
to compilers as much as to the primary server: every server that compiles catalogs
from eyaml-backed Hiera data has to run on a host that is not in FIPS mode. FIPS
agents work against such servers, and the agent's Ruby decrypts the same values
without trouble, for example with `eyaml decrypt`.

### puppetlabs-java_ks cannot import a private key

Importing a private key with the `java_ks` type fails on a FIPS agent with
`mac generation error`. The module builds a PKCS12 bundle with a MAC whose key
derivation is not available from the agent's FIPS provider. A fix is proposed
upstream in [puppetlabs-java_ks pull request 483][java_ks_pr]; until it is
released, create keystores on a host that is not in FIPS mode or with `keytool`
directly.

### SSH on a FIPS host refuses Ed25519 keys

`sshd` on a FIPS host offers no Ed25519 host key and rejects Ed25519 user keys
(`signature algorithm ssh-ed25519 not in PubkeyAcceptedAlgorithms` in its log);
ECDSA and RSA keys work, and `ssh-keygen -t ed25519` on the host itself refuses
with `ED25519 keys are not allowed in FIPS mode`. Give OpenBolt an ECDSA or RSA
key for FIPS targets. If you generate an ECDSA key for this, write it in PEM format
(`ssh-keygen -t ecdsa -m PEM`): in testing, the SSH library OpenBolt uses failed to
sign with the same key in the OpenSSH format. The same applies to anything else that
reaches the host over SSH with an Ed25519 key, such as a deploy key r10k uses on a
FIPS compiler: switch it to ECDSA or RSA, or use HTTPS.

`ssh-keyscan` run on a FIPS host fails against hosts that are not in FIPS mode. It
proposes the default key exchange list, the peer picks an exchange that FIPS mode
does not allow (`sntrup761`, `c25519`, or `mlkem768x25519`, depending on the peer),
and the scan exits with status 1 and `Key exchange type ... is not allowed in FIPS
mode`. Against another FIPS host it works. Collect host keys for `known_hosts` from
a host that is not in FIPS mode, or from the provider's published list.

### MD5 through OpenSSL is unavailable, MD5 in Puppet code is not

The agent's bundled `openssl md5` and Ruby's `OpenSSL::Digest::MD5` fail on a FIPS
agent (`unsupported` and `Digest initialization failed`), as FIPS mode intends.
Puppet's `md5` function and `checksum => md5` on a `file` resource still work,
because they use Ruby's own `digest` library, which does not go through the FIPS
provider. A FIPS agent therefore does not stop Puppet code from computing MD5; if
your policy forbids it, look for `md5` in your modules yourself.

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
cd /opt/puppetlabs/puppet/ssl
sudo cp --preserve openssl-fips.cnf openssl.cnf
/opt/puppetlabs/puppet/bin/ruby -ropenssl -e 'puts OpenSSL.fips_mode'
```

Reinstalling the agent package (`dnf reinstall openvox-agent`) has the same effect.

## Checking a host

On an agent:

```console
$ cat /proc/sys/crypto/fips_enabled
1
$ rpm -q openvox-agent
openvox-agent-8.31.1-1.redhatfips9.x86_64
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
openvox-server-8.17.0-1.redhatfips9.noarch
$ ps -o args= -C java | cut -d' ' -f1
/usr/bin/java
$ ps -o args= -C java | tr ' ' '\n' | grep java.security
-Djava.security.properties==/opt/puppetlabs/server/data/puppetserver/java.security.fips
$ /usr/bin/java -version
openjdk version "17.0.17" 2026-07-21 LTS
```

The second command prints the JVM binary in use (`JAVA_BIN` in
`/etc/sysconfig/puppetserver`, `/usr/bin/java` by default), the third shows that
it runs with the FIPS security properties, and the fourth confirms the Java
version. That properties file lists the Bouncy Castle FIPS providers first and
replaces the JDK's own list.

## Related pages

- [Supported platforms][supported_platforms] marks the operating systems with FIPS builds.
- [Component versions in recent releases][component_versions] lists the OpenSSL and Java versions per release.
- [Repositories and mirrors][mirrors] and [OpenVox repositories and packages][openvox_platform] describe the repository layout.
