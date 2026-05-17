---
layout: default
title: "OpenVox Server Configuration Files: web-routes.conf"
---

The `web-routes.conf` file configures the OpenVox Server `web-router-service`, which sets mount points for OpenVox Server's web applications.
You should not modify these mount points, as OpenVox agents rely on OpenVox Server mounting them to specific URLs.

For an overview, see [OpenVox Server Configuration](./configuration.html). To configure the `webserver` service, see the [`webserver.conf` documentation](./config_file_webserver.html).

## Example

The `web-routes.conf` file looks like this:

```text
# Configure the mount points for the web apps.
web-router-service: {
    # These two should not be modified because the Puppet 4 agent expects them to
    # be mounted at these specific paths.
    "puppetlabs.services.ca.certificate-authority-service/certificate-authority-service": "/puppet-ca"
    "puppetlabs.services.master.master-service/master-service": "/puppet"
    "puppetlabs.services.legacy-routes.legacy-routes-service/legacy-routes-service": ""

    # This controls the mount point for the Puppet administration API.
    "puppetlabs.services.puppet-admin.puppet-admin-service/puppet-admin-service": "/puppet-admin-api"
}
```
