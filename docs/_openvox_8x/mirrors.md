---
layout: default
title: "Repositories and mirrors"
---

[install_linux]: install_linux.html
[openvox_platform]: openvox_platform.html
[planning_41]: https://github.com/OpenVoxProject/planning/issues/41
[mirroring_blog]: https://voxpupuli.org/blog/2025/03/04/openvox-downloads-and-mirroring/
[apt_module]: https://forge.puppet.com/modules/puppetlabs/apt
[yumrepo_type]: https://forge.puppet.com/modules/puppetlabs/yumrepo_core

OpenVox packages are published from a single server in Germany. If downloads
from `voxpupuli.org` are slow in your region, install from one of the public
mirrors listed on this page, or run a mirror of your own.

For the package names and the standard install flow, see
[OpenVox repositories and packages][openvox_platform] and
[Installing OpenVox agent: Linux][install_linux].

## Canonical repository URLs

Vox Pupuli hosts the OpenVox repositories and downloads under these names:

| URL | Contents |
| --- | --- |
| [apt.voxpupuli.org](https://apt.voxpupuli.org) | Debian and Ubuntu repositories, plus the `openvox*-release` packages for them |
| [yum.voxpupuli.org](https://yum.voxpupuli.org) | Red Hat family, Fedora, Amazon Linux, and SLES repositories, plus their `openvox*-release` packages |
| [downloads.voxpupuli.org](https://downloads.voxpupuli.org) | Windows and macOS installers |
| [artifacts.voxpupuli.org](https://artifacts.voxpupuli.org) | Build artifacts from the OpenVox release pipelines |
| [rsync.voxpupuli.org](https://rsync.voxpupuli.org) | All of the above, under `apt/`, `yum/`, `downloads/`, and `artifacts/` |

These names all resolve to the same server. `rsync.voxpupuli.org` is the tree that
mirrors copy, so every mirror uses the same layout: the `apt/` directory on a
mirror corresponds to `apt.voxpupuli.org`, `yum/` to `yum.voxpupuli.org`, and so on.

> **Note:** `apt.overlookinfratech.com`, `yum.overlookinfratech.com`, and the
> `s3.osuosl.org/openvox-*` buckets are older names for the same server. They are
> not mirrors, and using them does not change download speed.

### Repository layout

Within the `apt/` tree, each distribution is a suite named after the OS and its
release, such as `debian12` or `ubuntu24.04`, and each OpenVox series is a
component within that suite, such as `openvox8`.

Within the `yum/` tree, repositories follow the pattern
`<series>/<platform>/<version>/<arch>`, where `<platform>` is `el`, `fedora`,
`amazon`, `sles`, or `redhatfips`. For example, the OpenVox 8 repository for
EL 9 on x86_64 is `yum/openvox8/el/9/x86_64/`.

### Signing key

All packages and repository metadata are signed with the Vox Pupuli key
`Vox Pupuli <openvox@voxpupuli.org>`, fingerprint
`0E26 4299 8700 2418 F951 3F2A 5FB9 99C2 D62F F3D9`. The key is available at the
root of the `apt/` and `yum/` trees as `GPG-KEY-openvox.pub` (ASCII-armored), and
at the root of the `apt/` tree as `openvox-keyring.gpg` (binary keyring). The
`openvox*-release` packages install the same key. Mirrors carry these files, so
you can fetch the key from the mirror you use.

## Public mirrors

The following organizations mirror the OpenVox repositories:

| Mirror | Location | Protocols | Sync interval |
| --- | --- | --- | --- |
| [mirror.rackspace.com/openvox/](https://mirror.rackspace.com/openvox/) | Rackspace, six sites worldwide | http, https | Daily |
| [mirror.grid.uchicago.edu/pub/openvox/](https://mirror.grid.uchicago.edu/pub/openvox/) | University of Chicago, US | http, https, rsync | Every 6 hours |
| [linorg.usp.br/voxpopuli/](https://linorg.usp.br/voxpopuli/) | University of São Paulo, Brazil | http, https, rsync | Daily |
| [ftp.gwdg.de/pub/linux/openvox/](https://ftp.gwdg.de/pub/linux/openvox/) | GWDG, Germany | http, https, rsync, ftp | Every 12 hours |
| [www.mirrorservice.org/sites/](https://www.mirrorservice.org/sites/) | University of Kent, UK | http, https, rsync | Four times daily |
| [openvox.repo.nfrance.com/](https://openvox.repo.nfrance.com/) | NFrance, Toulouse, France | http, https | Not published |
| [openvox.mirror.liquidtelecom.com/](https://openvox.mirror.liquidtelecom.com/) | Liquid Intelligent Technologies, Nairobi, Kenya | http, https, rsync | Every 6 hours |

Most mirrors carry the full `rsync.voxpupuli.org` tree with the same layout. The
exceptions:

- Rackspace serves `apt/`, `yum/`, and `downloads/`, but not `artifacts/`. Its
  six sites (three in the US, UK, Hong Kong, Australia) share one hostname, and
  geographic DNS answers from the nearest one.
- The UK Mirror Service uses one directory per hostname instead of one tree:
  `sites/apt.voxpupuli.org/`, `sites/yum.voxpupuli.org/`,
  `sites/downloads.voxpupuli.org/`, and `sites/artifacts.voxpupuli.org/`. Its
  rsync service is `rsync.mirrorservice.org`.
- NFrance serves `apt/` and `yum/` only.

Choose the mirror closest to your nodes. Rackspace answers DNS queries from the
nearest of its six sites, which makes it a reasonable choice for nodes spread
across several regions.

> **Note:** This table was last checked on 2026-09-10. The OpenVox project does
> not operate or monitor these mirrors, and a mirror can fall behind or go
> offline without notice. Before you depend on a mirror, compare the newest
> package in a repository directory against the same directory on
> `yum.voxpupuli.org` or `apt.voxpupuli.org`. To report a problem with the
> table, open an issue on
> [openvox-docs](https://github.com/OpenVoxProject/openvox-docs/issues).

## Using a mirror

The `openvox8-release` packages always configure `apt.voxpupuli.org` or
`yum.voxpupuli.org`. To install from a mirror, write the repository definition
yourself instead of installing the release package. The examples below use
`mirror.rackspace.com`; replace the base URL with the mirror you chose, and adjust
the OS name and version to match your platform.

### yum and dnf

Create `/etc/yum.repos.d/openvox8.repo`. This example is for EL 9:

```ini
[openvox8]
name=OpenVox 8 Repository el 9 - $basearch
baseurl=https://mirror.rackspace.com/openvox/yum/openvox8/el/9/$basearch
gpgkey=https://mirror.rackspace.com/openvox/yum/GPG-KEY-openvox.pub
enabled=1
gpgcheck=1
```

Then install the package you need:

```console
sudo dnf install openvox-agent
```

### apt

Download the keyring from the mirror, then create
`/etc/apt/sources.list.d/openvox8.list`. This example is for Ubuntu 24.04:

```console
sudo install -d -m 0755 /etc/apt/keyrings
sudo curl -fsSL -o /etc/apt/keyrings/openvox-keyring.gpg https://mirror.rackspace.com/openvox/apt/openvox-keyring.gpg
```

```text
deb [signed-by=/etc/apt/keyrings/openvox-keyring.gpg] https://mirror.rackspace.com/openvox/apt ubuntu24.04 openvox8
```

The release package also installs an apt preference that pins `openvox-agent` to
the Vox Pupuli origin, so that the OpenVox package wins over a package of the same
name from another repository. Mirrors serve the same release metadata, so the pin
still matches. Create `/etc/apt/preferences.d/openvox-release.pref` with the same
content:

```text
Package: openvox-agent
Pin: release o=Vox*
Pin-Priority: 1001
```

Then install the package you need:

```console
sudo apt update
sudo apt install openvox-agent
```

### Managing the repository with Puppet code

If you manage repository configuration with OpenVox itself, the following
resources produce the same configuration as the files above. Set `$mirror` to
the base of the mirror tree, that is, the directory that contains `apt/` and
`yum/`. To use the canonical repositories instead of a mirror, set it to
`https://rsync.voxpupuli.org`.

On the Red Hat family, use the built-in [`yumrepo`][yumrepo_type] type:

```puppet
$mirror = 'https://mirror.rackspace.com/openvox'
$os_major = $facts['os']['release']['major']

yumrepo { 'openvox8':
  descr    => "OpenVox 8 Repository el ${os_major} - \$basearch",
  baseurl  => "${mirror}/yum/openvox8/el/${os_major}/\$basearch",
  gpgkey   => "${mirror}/yum/GPG-KEY-openvox.pub",
  enabled  => 1,
  gpgcheck => 1,
}
```

On Debian and Ubuntu, use `apt::source` and `apt::pin` from the
[puppetlabs-apt][apt_module] module:

```puppet
$mirror = 'https://mirror.rackspace.com/openvox'
$os_name = downcase($facts['os']['name'])
$os_major = $facts['os']['release']['major']

apt::source { 'openvox8':
  location => "${mirror}/apt",
  release  => "${os_name}${os_major}",
  repos    => 'openvox8',
  key      => {
    'name'   => 'openvox-keyring.gpg',
    'source' => "${mirror}/apt/openvox-keyring.gpg",
  },
}

apt::pin { 'openvox-release':
  packages   => 'openvox-agent',
  originator => 'Vox*',
  priority   => 1001,
}
```

## Running your own mirror

You can mirror the repositories for your own network, for example to serve hosts
without internet access, or offer a public mirror for your region. The origin
server exposes two rsync modules, described in the
[OpenVox downloads and mirroring][mirroring_blog] announcement:

| Module | Contents | Approximate size |
| --- | --- | --- |
| `rsync://rsync.voxpupuli.org/packages` | `apt/`, `yum/`, and `downloads/` | 100 GB |
| `rsync://rsync.voxpupuli.org/all` | Everything, including `artifacts/` | 500 GB |

These sizes are from September 2026 and grow with every release. Most mirrors
need only the `packages` module. The `artifacts/` directory holds build output
from the release pipelines and is the largest part of the tree.

Keep the directory layout of the module so that the examples on this page work
with your mirror unchanged. For example:

```console
rsync -a --delete --delay-updates rsync://rsync.voxpupuli.org/packages/ /srv/mirror/openvox/
```

Sync from `rsync.voxpupuli.org`, not from another mirror. The public mirrors
listed above sync between every 6 hours and once a day.

To have a public mirror listed on this page, add a comment to
[OpenVoxProject/planning#41][planning_41] with the URL, location, protocols,
sync interval, and a contact address, and open a pull request or issue on
[openvox-docs](https://github.com/OpenVoxProject/openvox-docs/issues) to add it
to the table.
