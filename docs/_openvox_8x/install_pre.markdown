---
layout: default
title: "Installing OpenVox: Pre-install tasks"
---

[sysreqs]: ./system_requirements.html
[ruby]: ./system_requirements.html#basic-requirements
[architecture]: ./architecture.html
[openvox-db]: /openvoxdb/latest/
[server_setting]: ./configuration.html#server

To ease your OpenVox installation, complete these tasks before installing Puppet agent.

1. Decide on a deployment type.

   OpenVox usually uses an agent-server (client-server) architecture, but it can also run in a self-contained architecture. Your choice determines which packages you install, and what extra configuration you need to do.

   Additionally, consider using [OpenVox-DB][], which enables extra Puppet features and makes it easy to query and analyze Puppet's data about your infrastructure.

   [Learn more about OpenVox's architectures here.][architecture]

2. If you choose the standard agent-server architecture, you need to decide which servers act as the OpenVox server (and the [OpenVox-DB][] server, if you choose to use it).

   Completely install and configure OpenVox on any OpenVox servers and OpenVox-DB servers before installing on any agent nodes. The server must be running some kind of \*nix. Windows machines can't be OpenVox servers.

   An OpenVox server is a dedicated machine, so it must be reachable at a reliable hostname. Agent nodes default to contacting the server at the hostname `puppet`. If you make sure this hostname resolves to the server, you can skip changing [the `server` setting][server_setting] and reduce your setup time.

3. Check OS versions and system requirements.

   See the [system requirements][sysreqs] for the version of OpenVox you are installing, and consider the following:

   * Your OpenVox servers should be able to handle the amount of agents they'll need to serve.
   * Systems we provide official packages for have an easier install path.
   * Systems we don't provide packages for might still be able to run OpenVox, as long as the version of Ruby is suitable and the prerequisites are installed, but it means a more complex and often time consuming install path.

4. Check your network configuration.

   In an agent-server deployment, you must prepare your network for OpenVox's traffic.

   * **Firewalls:** The OpenVox server must allow incoming connections on port 8140, and agent nodes must be able to connect to the server on that port.
   * **Name resolution:** Every node must have a unique hostname. **Forward and reverse DNS** must both be configured correctly. If your site lacks DNS, you must write an `/etc/hosts` file on each node.
     * **Note:** The default OpenVox server hostname is `puppet`. Your agent nodes can be ready sooner if this hostname resolves to your OpenVox server.

5. Set timekeeping on your OpenVox server.

   The time must be set accurately on the OpenVox server that acts as the certificate authority. If the time is wrong, it can mistakenly issue agent certificates from the distant past or future, which other nodes treat as expired. There are modules, such as the chrony or systemd module that can help you with this.

Install OpenVox Server before installing OpenVox on your agent nodes. If you're using OpenVox-DB, install it once OpenVox Server is up and running. Once you have completed these steps and configured your server, you can install OpenVox agents.

* [Installing OpenVox agent on Linux](./install_linux.html)
* [Installing OpenVox agent on Windows](./install_windows.html)
* [Installing OpenVox agent on macOS](./install_osx.html)