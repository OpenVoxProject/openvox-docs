---
layout: default
title: "OpenVox Server Configuration Files: product.conf"
---

The `product.conf` file contains settings that determine how OpenVox Server interacts with Puppet, Inc., such as automatic update checking and analytics data collection.

## Settings

The `product.conf` file doesn't exist in a default OpenVox Server installation; to configure its settings, you must create it in OpenVox Server's `conf.d` directory
(located by default at `/etc/puppetlabs/puppetserver/conf.d`). This file is a [HOCON-formatted](https://github.com/typesafehub/config/blob/master/HOCON.md) configuration file with the following settings:

- Settings in the `product` section configure update checking and analytics data collection:

  - `check-for-updates`: If set to `false`, OpenVox Server will not automatically check for updates, and will not send analytics data to Puppet.
    If this setting is unspecified (default) or set to `true`, OpenVox Server checks for updates upon start or restart, and every 24 hours thereafter, by sending the following data to Puppet:
    - Product name
    - OpenVox Server version
    - IP address
    - Data collection timestamp
    OpenVox requests this data as one of the many ways we learn about and work with our community. The more we know about how you use OpenVox, the better we can address your needs.
    No personally identifiable information is collected, and the data we collect is never used or shared outside of OpenVox.

### Example

``` hocon
# Disabling automatic update checks and corresponding analytic data collection

product: {
    check-for-updates: false
}
```
