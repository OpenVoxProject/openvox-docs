---
layout: default
title: "Overview of OpenVox's architecture"
---

[agent_unix]: ./services_agent_unix.html
[agent_win]: ./services_agent_windows.html
[https_walkthrough]: ./subsystem_agent_master_comm.html
[server_http]: ./http_api/http_api_index.html
[auth.conf]: ./config_file_auth.html
[catalog_compilation]: ./subsystem_catalog_compilation.html
[report handlers]: ./report.html
[lang_basics]: ./lang_summary.html
[apply]: ./services_apply.html
[openvox-db]: /openvoxdb/latest/
[resource]: ./lang_resources.html
[OpenVox Server]: /openvox-server/latest/

You can configure systems with OpenVox either in a client-server architecture, using the **OpenVox agent** and **OpenVox server** applications, or in a stand-alone architecture, using the **OpenVox apply** application.

{:.concept}
## Catalogs

A catalog is a document that describes the desired system state for one specific computer. It lists all of the resources that need to be managed, as well as any dependencies between those resources.

OpenVox configures systems in two stages:

1. Compile a catalog.
2. Apply the catalog.

To compile a catalog, OpenVox uses several sources of information. For more info, see the pages on [basics of the OpenVox language][lang_basics] and [catalog compilation][catalog_compilation].

{:.concept}
## The agent-server architecture

When set up as an agent-server architecture, an OpenVox server controls the configuration information, and each managed agent node requests its own configuration catalog from the server.

In this architecture, managed nodes run the **OpenVox agent** application, usually as a background or scheduled service. One or more servers run the **OpenVox server** application, [OpenVox Server][].

Periodically, each OpenVox agent sends facts to the OpenVox server, and requests a catalog. The server compiles and returns that node's catalog, using several sources of information it has access to.

Once it receives a catalog, OpenVox agent applies it to the node by checking each [resource][] the catalog describes. If it finds any resources that are not in their desired state, it makes the changes necessary to correct them. Or, in no-op mode, it reports on what changes would have been done.

After applying the catalog, the agent sends a report to the OpenVox server.

For more information, see:

* [OpenVox Agent on \*nix Systems][agent_unix]
* [OpenVox Agent on Windows Systems][agent_win]
* [OpenVox Server][]

{:.section}
### Communications and security

OpenVox agent nodes and OpenVox servers communicate by HTTPS with client SSL verification.

The OpenVox Server provides an HTTP interface, with [various endpoints][server_http] available. When requesting or submitting anything to the server, the agent makes an HTTPS request to one of those endpoints.

Client-verified HTTPS means each server or agent must have an identifying SSL certificate. They each examine their counterpart's certificate to decide whether to allow an exchange of information.

OpenVox includes a built-in certificate authority for managing certificates. Agents can automatically request certificates through the server's HTTP API. You can use the **puppet ssl** command on an agent to inspect local certificates. The **puppetserver ca** command on the server manages new and existing certificates. Agents can then download the signed certificates.

For more information, see:

* [A walkthrough of OpenVox's HTTPS communications][https_walkthrough]
* [The OpenVox server's HTTP API][server_http]
* [The OpenVox server's auth.conf file][auth.conf]
* [Background reference on SSL and HTTPS.](/background/ssl/)

{:.concept}
## The stand-alone architecture

Alternatively, OpenVox can run in a stand-alone architecture, where each managed node has its own complete copy of your configuration info and compiles its own catalog.

In this architecture, managed nodes run the **OpenVox apply** application, usually as a scheduled task or cron job. You can also run it on demand for initial configuration of a server or for smaller configuration tasks.

Like the OpenVox server application, OpenVox apply needs access to several sources of configuration data, which it uses to compile a catalog for the node it is managing.

After OpenVox apply compiles the catalog, it immediately applies it by checking each [resource][] the catalog describes. If it finds any resources that are not in their desired state, it makes the changes necessary to correct them. Or, in no-op mode, it reports on what changes would have been needed.

After applying the catalog, OpenVox apply stores a report on disk. You can configure it to send reports to a central service.

For more information, see the documentation for [the OpenVox apply application][apply].

{:.concept}
## Differences between agent-server and stand-alone

In general, OpenVox apply can do the same things as the combination of OpenVox agent and OpenVox server, but there are several trade-offs around security and the ease of certain tasks.

If you don't have a preference, you should select the agent-server architecture. If you have questions, considering these trade-offs helps you make your decision.

* **Principle of least privilege.** In agent-server OpenVox, each agent only gets its own configuration, and is unable to see how other nodes are configured. With OpenVox apply, it's impractical to do this, so every node has access to complete knowledge about how your site is configured. Depending on how you're configuring your systems, this can potentially raise the risks of horizontal privilege escalation.
* **Ease of centralized reporting and inventory.** Agents send reports to the OpenVox server by default, and the server can be configured with any number of [report handlers][] to pass these on to other services. You can also connect the master to [OpenVox-DB][], a powerful tool for querying inventory and activity data. OpenVox apply nodes handle their own information, so if you're using OpenVox-DB or sending reports to another service, _each_ node needs to be configured and authorized to connect to it.
* **Ease of updating configurations.** Only OpenVox servers have the Puppet modules, main manifests, and other data necessary for compiling catalogs. This means that when you need to update your systems' configurations, you only need to update content on one (or a few) OpenVox servers. In a decentralized `puppet apply` deployment, you'll need to sync new configuration code and data to every node.
* **CPU and memory usage on managed machines.** Since OpenVox agent doesn't compile its own catalogs, it uses fewer resources on the machines it manages, leaving them with more capacity for their designated tasks.
* **Need for a dedicated OpenVox server.** The OpenVox server takes on the performance load of compiling all catalogs, and it should usually be a dedicated machine with a fast processor, lots of RAM, and a fast disk. Not everybody wants to (or is able to) allocate that, and OpenVox apply can get around the need for it.
* **Need for good network connectivity.** Agents need to be able to reach the OpenVox server at a reliable hostname in order to configure themselves. If a system lives in a degraded or isolated network environment, you might want it to be more self-sufficient.
* **Security overhead.** Agents and servers use HTTPS to secure their communications and authenticate each other, and every system involved needs an SSL certificate. OpenVox includes a built-in CA to easily manage certificates, but it's even easier to not manage them at all. (Of course, you'll still need to manage security somehow, since you're probably using Rsync or something to update OpenVox content on every node.)
