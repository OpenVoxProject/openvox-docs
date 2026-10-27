---
layout: default
title: "OpenVox Server Configuration Files: logback.xml"
---

OpenVox Server’s logging is routed through the Java Virtual Machine's [Logback library](http://logback.qos.ch/) and configured in an XML file typically named `logback.xml`.

> **Note:** This document covers basic, commonly modified options for OpenVox Server logs. Logback is a powerful library with many options. For detailed information on configuring Logback, see the
> [Logback Configuration Manual](http://logback.qos.ch/manual/configuration.html).
>
> For advanced logging configuration tips specific to OpenVox Server, such as configuring Logstash or outputting logs in JSON format, see [Advanced Logging Configuration](./config_logging_advanced.html).

## OpenVox Server logging

By default, OpenVox Server logs messages and errors to `/var/log/puppetlabs/puppetserver/puppetserver.log`. The default log level is ‘INFO’, and OpenVox Server sends nothing to `syslog`. You can change OpenVox
Server's logging behavior by editing `/etc/puppetlabs/puppetserver/logback.xml`, and you can specify a different Logback config file in [`global.conf`](./config_file_global.html).

You can restart the `puppetserver` service for changes to take effect, or enable [configuration scanning](#scan-and-scanperiod) to allow changes to be recognized at runtime.

OpenVox Server also relies on Logback to manage, rotate, and archive Server log files. Logback archives Server logs when they exceed 10MB, and when the total size of all Server logs exceeds 1GB, it automatically
deletes the oldest logs.

### Settings

#### `level`

To modify OpenVox Server's logging level, change the `level` attribute of the `root` element. By default, the logging level is set to `info`:

    <root level="info">

Supported logging levels, in order from most to least information logged, are `trace`, `debug`, `info`, `warn`, and `error`. For instance, to enable debug logging for Puppet Server, change `info` to `debug`:

    <root level="debug">

OpenVox Server profiling data is included at the `debug` logging level.

You can also change the logging level for JRuby logging from its defaults of `error` and `info` by setting the `level` attribute of the `jruby` element. For example, to enable debug logging for JRuby, set the
attribute to `debug`:

    <jruby level="debug">

#### Logging location

You can change the file to which OpenVox Server writes its logs in the `appender` section named `F1`. By default, the location is set to `/var/log/puppetlabs/puppetserver/puppetserver.log`:

    ...
        <appender name="F1" class="ch.qos.logback.core.FileAppender">
            <file>/var/log/puppetlabs/puppetserver/puppetserver.log</file>
    ...

To change this to `/var/log/puppetserver.log`, modify the contents of the `file` element:

            <file>/var/log/puppetserver.log</file>

The user account that owns the OpenVox Server process must have write permissions to the destination path.

#### `scan` and `scanPeriod`

Logback supports noticing and reloading configuration changes without requiring a restart, a feature Logback calls **scanning**. To enable this, set the `scan` and `scanPeriod` attributes in the
`<configuration>` element of `logback.xml`:

    <configuration scan="true" scanPeriod="60 seconds">

Due to a bug in Logback, the `scanPeriod` must be set to a value; setting only `scan="true"` will not enable configuration scanning. Scanning is enabled by
default in the `logback.xml` configuration packaged with OpenVox Server.

**Note:** The HTTP request log does not currently support the scan feature. Adding the `scan` or `scanPeriod` settings to `request-logging.xml` will have no effect.

## HTTP request logging

OpenVox Server logs HTTP traffic separately, and this logging is configured in a different Logback configuration file located at `/etc/puppetlabs/puppetserver/request-logging.xml`. To specify a different Logback
configuration file, change the `access-log-config` setting in OpenVox Server's [`webserver.conf`](./config_file_webserver.html) file.

The HTTP request log uses the same Logback configuration format and settings as the OpenVox Server log. It also lets you configure what it logs using patterns, which follow Logback's
[`PatternLayout` format](http://logback.qos.ch/manual/layouts.html#AccessPatternLayout).
