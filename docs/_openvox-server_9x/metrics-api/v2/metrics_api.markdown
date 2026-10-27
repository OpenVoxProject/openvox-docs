---
layout: default
title: "OpenVox Server: Metrics API v2"
---

By default, OpenVox Server enables two optional web APIs for [Java Management Extension (JMX)](https://docs.oracle.com/javase/tutorial/jmx/index.html) metrics, namely [managed beans (MBeans)](https://docs.oracle.com/javase/tutorial/jmx/mbeans/).
For the older metrics API, see [the `/metrics/v1` documentation](../v1/metrics_api.html).

## Jolokia endpoints

The v2 metrics endpoint uses the [Jolokia](https://jolokia.org) library, an extensive open-source metrics library with its own documentation.

The documentation below provides only the information you need to
use the metrics as configured by default for OpenVox Server, but Jolokia offers more features than are described below. Consult the
[Jolokia documentation](https://jolokia.org/documentation.html) for more information.

For security reasons, we enable only the read-access Jolokia interface by default:

- `read`
- `list`
- `version`
- `search`

### Configuring Jolokia

To change the security access policy, create the `/etc/puppetlabs/puppetserver/jolokia-access.xml` file with contents that follow the [Jolokia access policy](https://jolokia.org/reference/html/security.html)
and uncomment the `metrics.metrics-webservice.jolokia.servlet-init-params.policyLocation` parameter before restarting OpenVox Server.

The `metrics.metrics-webservice.jolokia.servlet-init-params` table within the [`/etc/puppetlabs/puppetserver/conf.d/metrics.conf`](../../config_file_metrics.html) file provides more configuration options.
See Jolokia's [agent initialization documentation](https://jolokia.org/reference/html/agents.html#agent-war-init-params) for all of the available options.

### Disabling the endpoints

To disable the v2 endpoints, set the `metrics.metrics-webservice.jolokia.enabled` parameter in `metrics.conf` to `false`.

## Usage

You can query the metrics v2 API using `GET` or `POST` requests.

### `GET /metrics/v2/`

(Introduced in Puppet Server 5)

This endpoint requires an operation, and depending on the operation can accept or might require an additional query:

```http
GET /metrics/v2/<OPERATION>/<QUERY>
```

#### Response

A successful request returns a JSON document.

#### Examples

To list all valid mbeans querying the metrics endpoint

```http
GET /metrics/v2/list
```

Which should return a response similar to

```json
{
  "request": {
    "type": "list"
  },
  "value": {
    "java.util.logging": {
      "type=Logging": {
        "op": {
          "getLoggerLevel": {
            ...
          },
          ...
        },
        "attr": {
          "LoggerNames": {
            "rw": false,
            "type": "[Ljava.lang.String;",
            "desc": "LoggerNames"
          },
          "ObjectName": {
            "rw": false,
            "type": "javax.management.ObjectName",
            "desc": "ObjectName"
          }
        },
        "desc": "Information on the management interface of the MBean"
      }
    },
    ...
  }
}
```

So, from the example above we could query for the registered logger names with this HTTP call:

```http
GET /metrics/v2/read/java.util.logging:type=Logging/LoggerNames
```

Which would return the JSON document

```json
{
  "request": {
    "mbean": "java.util.logging:type=Logging",
    "attribute": "LoggerNames",
    "type": "read"
  },
  "value": [
    "javax.management.snmp",
    "global",
    "javax.management.notification",
    "javax.management.modelmbean",
    "javax.management.timer",
    "javax.management",
    "javax.management.mlet",
    "javax.management.mbeanserver",
    "javax.management.snmp.daemon",
    "javax.management.relation",
    "javax.management.monitor",
    "javax.management.misc",
    ""
  ],
  "timestamp": 1497977258,
  "status": 200
}
```

The MBean names can then be created by joining the the first two keys of the value table with a colon (the `domain` and `prop list` in Jolokia parlance). Querying the MBeans is achieved via the `read`
operation. The `read` operation has as its GET signature:

```http
GET /metrics/v2/read/<MBEAN NAMES>/<ATTRIBUTES>/<OPTIONAL INNER PATH FILTER>
```

### `POST /metrics/v2/<OPERATION>`

You can also submit a POST request with the query as a JSON document in the body of the POST.

## Filtering

The new Jolokia-based metrics API also provides globbing (wildcard selection) and response filtering features.

### Example

You can combine both of these features to query garbage collection data, but return only the collection counts and times.

```text
GET metrics/v2/read/java.lang:name=*,type=GarbageCollector/CollectionCount,CollectionTime
```

This returns a JSON response:

```json
{
  "request": {
    "mbean": "java.lang:name=*,type=GarbageCollector",
    "attribute": ["CollectionCount", "CollectionTime"],
    "type": "read"
  },
  "value": {
    "java.lang:name=PS Scavenge,type=GarbageCollector": {
      "CollectionTime": 1314,
      "CollectionCount": 27
    },
    "java.lang:name=PS MarkSweep,type=GarbageCollector": {
      "CollectionTime": 580,
      "CollectionCount": 5
    }
  },
  "timestamp": 1497977710,
  "status": 200
}
```

Refer to the [Jolokia protocol documentation](https://jolokia.org/reference/html/protocol.html) for more advanced usage.
