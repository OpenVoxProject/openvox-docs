---
layout: default
title: "OpenVox Server: Automatic CRL refresh"
---

OpenVox Server can automatically reload an updated CRL into the running SSL context, so that the revocation of an agent's certificate no longer requires a restart of the service to take effect.
Revocation is now transparent and requires no service downtime.

If you are upgrading and have modified your ca.cfg, adding the following line manually may be required.
See [Service Bootstraping](./configuration.html#service-bootstrapping) for information on how to update your OpenVox Server's services bootstrap configuration.

`puppetlabs.trapperkeeper.services.watcher.filesystem-watch-service/filesystem-watch-service`

## Implementation

Automatic CRL refresh leverages the the [trapperkeeper file system watcher](https://github.com/openvoxproject/trapperkeeper-filesystem-watcher) to watch for changes to the CRL file, and loads the updated
CRL on change.

### Contributors

Thanks to Jeremy Barlow, who laid the groundwork for this feature in OpenVox Server.
