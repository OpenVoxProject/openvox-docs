---
layout: default
title: "Installing OpenVox: Before you begin"
---

[sysreqs]: ./system_requirements.html
[architecture]: ./architecture.html
[openvoxdb]: /openvoxdb/latest/
[openvox_server]: /openvox-server/latest/install_from_packages.html
[server_setting]: ./configuration.html#server

OpenVox 9 uses the same commands and configuration paths as modern Puppet releases.
You can keep using your existing tooling and `/etc/puppetlabs/` configuration, but
you cannot install both Puppet and OpenVox on the same system at the same time.

Before installing OpenVox:

1. Decide which deployment model you want.

   OpenVox can run in an agent-server layout or in a standalone `puppet apply`
   workflow. Your choice determines which packages you need and which hosts must
   be available first. For background, see the [architecture overview][architecture].

2. Decide which systems will run OpenVox Server and, if you use it, [OpenVoxDB][openvoxdb].

   Install and validate your server components before you roll out `openvox-agent`
   to managed nodes. See the [OpenVox Server documentation][openvox_server] for
   server installation instructions. In agent-server deployments, Linux and other
   Unix-like systems are the supported server platforms.

3. Review supported platforms and capacity requirements.

   Use the [system requirements][sysreqs] page to confirm that your chosen systems
   are supported and sized appropriately for the number of nodes they will manage.

4. Plan your migration if you are replacing legacy Puppet packages.

   OpenVox packages replace the legacy Puppet packages and continue using the
   existing `/etc/puppetlabs/` tree. Back up `/etc/puppetlabs/` before starting
   any in-place migration, especially on server nodes.

5. Check DNS, certificates, and networking.

   In agent-server deployments, agents must be able to reach the server on port
   `8140`. Forward and reverse DNS should be correct for every node. If you want
   agents to use the default server name, make sure `puppet` resolves correctly;
   otherwise set the [`server` setting][server_setting] explicitly.

6. Verify time synchronization on the certificate authority.

   Incorrect system time can cause certificate issuance and validation failures.
   Make sure the CA host is using reliable time synchronization before any agents
   request certificates.

Once you have completed these checks, continue with the install page for your platform:

- [Install OpenVox agent on Linux](./install_linux.html)
- [Install OpenVox agent on Windows](./install_windows.html)
- [Install OpenVox agent on macOS](./install_osx.html)
