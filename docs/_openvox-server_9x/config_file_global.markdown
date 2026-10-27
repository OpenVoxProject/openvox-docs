---
layout: default
title: "OpenVox Server Configuration Files: global.conf"
---

The `global.conf` file contains global configuration settings for OpenVox Server. For an overview, see [OpenVox Server Configuration](./configuration.html).

You shouldn't typically need to make changes to this file. However, you can change the `logging-config` path for the logback logging configuration file if necessary. For more information about the logback file,
see <http://logback.qos.ch/manual/configuration.html>.

## Example

```text
global: {
    logging-config: /etc/puppetlabs/puppetserver/logback.xml
}
```
