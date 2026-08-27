---
layout: default
title: "Formats: Reports"
---

[about reporting]: reporting_about.html
[report processors]: report.html
[custom report processor]: reporting_write_processors.html
[reportdir]: /openvox/latest/configuration.html#reportdir
[exclude_unchanged_resources]: /openvox/latest/configuration.html#exclude_unchanged_resources

Every time OpenVox applies a catalog, it builds a `Puppet::Transaction::Report` object describing what
happened during the run: the status of every resource, the events Puppet applied, the log messages it
produced, and metrics about the run as a whole. That object is what [report processors][report processors]
receive, and it is what OpenVox serializes when it sends a report to a server or writes one to disk.

This page describes **report format 12**, which OpenVox 8 produces. Use it when you write a
[custom report processor][custom report processor] or consume reports from another tool. For an
introduction to how reporting works, see [About reporting][about reporting].

## How reports are serialized

A report is a nested structure of five object types:

- A **Report** at the top level.
- **Metric** objects, one per metric category, under `metrics`.
- **ResourceStatus** objects, one per resource, under `resource_statuses`.
- **Event** objects, under each resource status's `events`.
- **Log** objects under `logs`.

When an agent sends a report to OpenVox Server, it serializes this structure as JSON. The built-in
`store` processor instead writes it to [`reportdir`][reportdir] as YAML containing Ruby object tags, so
prefer the JSON form when you exchange reports between tools.

The canonical machine-readable definition is the
[`report.json` schema](https://github.com/OpenVoxProject/openvox/blob/main/api/schemas/report.json) in the
OpenVox source.

## Report format versions

The `report_format` field identifies the structure of the report, not the version of OpenVox that produced
it. It changes only when the objects that make up a report change.

Every OpenVox release produces format 12. OpenVox inherited that format from the Puppet 8 codebase it
forked from, and the format has not changed since Puppet 7.0.0, so a tool that reads format 12 works
across every OpenVox version.

Earlier formats come from Puppet releases that predate OpenVox. You encounter them only in reports from
older Puppet agents:

| Format | First shipped in                        |
| ------ | --------------------------------------- |
| 7      | Puppet 5.0.0                            |
| 8      | Puppet 5.4.0                            |
| 9      | Puppet 5.5.0                            |
| 10     | Puppet 5.5.3                            |
| 11     | Puppet 6.19.0                           |
| 12     | Puppet 7.0.0, and every OpenVox release |

Two of those changes still matter when you consume older reports. Format 11 added `server_used` and kept
`master_used` as an alias, so reports in that format carry both fields. Format 12 removed `master_used`
from the output, but OpenVox still reads it from incoming reports when `server_used` is absent, so older
reports remain loadable.

## Report

These fields are present in every report, although some values can be `null` when they do not apply to the
run:

| Field                   | Type             | Description |
| ----------------------- | ---------------- | ----------- |
| `host`                  | String           | The node the report is for. |
| `time`                  | String           | When the run started, in ISO 8601 format with a nine-digit second fraction. |
| `configuration_version` | Integer or String | The configuration version of the catalog. An integer of seconds since the epoch unless you set your own versioning scheme. |
| `transaction_uuid`      | String           | A UUID identifying the transaction. The agent sends the same UUID when it requests the catalog, which lets you connect a catalog to its report. |
| `report_format`         | Integer          | The report format version. `12` in OpenVox 8. |
| `puppet_version`        | String           | The version of OpenVox that produced the report. |
| `status`                | String           | The outcome of the run: `failed`, `changed`, or `unchanged`. |
| `transaction_completed` | Boolean          | Whether the transaction finished evaluating without an unhandled exception. |
| `noop`                  | Boolean          | Whether the run was started in no-op mode. |
| `noop_pending`          | Boolean          | Whether the run declined to apply changes because of no-op mode. |
| `environment`           | String           | The environment the run used, such as `production`. |
| `logs`                  | Array            | The Log objects generated during the run. |
| `metrics`               | Object           | A map of metric category name to Metric object. |
| `resource_statuses`     | Object           | A map of resource name, in `Type[title]` form, to ResourceStatus object. |
| `corrective_change`     | Boolean          | Whether any event in the run was a corrective change. |

These fields appear only when OpenVox has a value for them, so consumers must treat them as optional:

| Field                   | Type             | Description |
| ----------------------- | ---------------- | ----------- |
| `server_used`           | String           | The `servername:port` of the server that compiled the catalog. If failover occurred, this is the first server successfully contacted. Absent for `puppet apply` runs. |
| `catalog_uuid`          | String           | A UUID identifying a specific catalog, which lets you connect one catalog to multiple reports. |
| `code_id`               | String           | The identifier of the code the compiler used. |
| `job_id`                | String           | The identifier of the job this transaction belongs to. |
| `cached_catalog_status` | String           | Whether a cached catalog was used, and why: `not_used`, `explicitly_requested`, or `on_failure`. |

## Metric

Each entry in `metrics` is a Metric object with three fields:

| Field    | Type   | Description |
| -------- | ------ | ----------- |
| `name`   | String | The category name: `resources`, `time`, `events`, or `changes`. |
| `label`  | String | The category name in title form, such as `Resources`. |
| `values` | Array  | The measurements in this category. |

Every entry in `values` is itself a three-element array of `[name, label, value]`, for example
`["changed", "Changed", 2]`.

The four categories measure:

- `resources` — counts of resources in each state: `total`, `skipped`, `failed`, `failed_to_restart`,
  `restarted`, `changed`, `out_of_sync`, `scheduled`, and `corrective_change`. All of these are present
  even when the count is zero.
- `time` — how long things took, in seconds. Contains one entry per resource type that OpenVox evaluated,
  named after the type in lowercase, plus `config_retrieval`, `transaction_evaluation`,
  `catalog_application`, and `total`.
- `events` — counts of events by status. `total`, `success`, and `failure` are always present; `noop` and
  `audit` appear only when the run produced events with those statuses.
- `changes` — a single `total` entry counting the changes in the transaction.

## ResourceStatus

Each value in `resource_statuses` describes what happened to one resource:

| Field               | Type             | Description |
| ------------------- | ---------------- | ----------- |
| `resource_type`     | String           | The capitalized type name, such as `File`. |
| `title`             | String           | The resource title. |
| `resource`          | String           | The resource name in `Type[title]` form. Deprecated: this always matches the key this status is stored under. |
| `provider_used`     | String or null   | The provider the resource used. |
| `file`              | String or null   | The manifest that declared the resource. |
| `line`              | Integer or null  | The line in that manifest. |
| `evaluation_time`   | Number or null   | How long the resource took to evaluate, in seconds. |
| `change_count`      | Integer          | How many properties changed. |
| `out_of_sync_count` | Integer          | How many properties were out of sync. |
| `tags`              | Array of String  | The tags on the resource. |
| `time`              | String           | When the resource was evaluated, in ISO 8601 format with a nine-digit second fraction. |
| `events`            | Array            | The Event objects for this resource. |
| `skipped`           | Boolean          | Whether OpenVox skipped the resource. |
| `failed_to_restart` | Boolean          | Whether OpenVox failed to restart the resource after another resource notified it. |
| `containment_path`  | Array of String  | The containers, such as classes and defined types, that contain the resource, ordered from outermost to innermost. |
| `corrective_change` | Boolean          | Whether a change or no-op event on this resource corrected unexpected drift. |
| `out_of_sync`       | Boolean          | Deprecated: true when `out_of_sync_count` is greater than zero. |
| `changed`           | Boolean          | Deprecated: true when `change_count` is greater than zero. |
| `failed`            | Boolean          | Deprecated: whether OpenVox hit an error while evaluating the resource. |

The [`exclude_unchanged_resources`][exclude_unchanged_resources] setting, which defaults to `true`, omits
resources that did not change from the serialized report. Resources that changed, failed, or were skipped
are kept, so do not assume every resource in the catalog appears here. The `resources` metrics still count
the whole catalog, which means `resources.total` is normally larger than the number of entries in
`resource_statuses`.
{: .tip }

## Event

Each event records one property that OpenVox audited or attempted to change:

| Field               | Type                          | Description |
| ------------------- | ----------------------------- | ----------- |
| `property`          | String or null                | The property the event is about. |
| `previous_value`    | String, Array, Object, or null | The value of the property before the change. |
| `desired_value`     | String, Array, Object, or null | The value the manifest specified. |
| `historical_value`  | String, Array, Object, or null | The audited value from an earlier run, when known. |
| `message`           | String                        | The log message this event generated. |
| `name`              | String                        | The name of the event, such as `file_created`. |
| `status`            | String                        | `success` if the property was out of sync and was corrected, `failure` if correcting it errored, `noop` if it was left alone because of no-op mode, or `audit` if the property was in sync and being audited. |
| `time`              | String                        | When the property was evaluated, in ISO 8601 format with a nine-digit second fraction. |
| `audited`           | Boolean                       | Whether the property is being audited. |
| `redacted`          | Boolean or null               | Whether OpenVox redacted the event, which it does for `Sensitive` values. |
| `corrective_change` | Boolean                       | Whether the event corrected unexpected drift between runs. |

OpenVox converts event values to strings before serializing them, so rich data types arrive as strings
rather than as their original Puppet types.

## Log

Each entry in `logs` is a log message from the run:

| Field     | Type            | Description |
| --------- | --------------- | ----------- |
| `level`   | String          | The severity: `debug`, `info`, `notice`, `warning`, `err`, `alert`, `emerg`, or `crit`. |
| `message` | String          | The message itself. |
| `source`  | String          | Where the message came from: a resource, a property of a resource, or the string `Puppet`. |
| `tags`    | Array of String | The tags on the source. |
| `time`    | String          | When the message was sent, in ISO 8601 format with a nine-digit second fraction. |
| `file`    | String or null  | The manifest that triggered the message. |
| `line`    | Integer or null | The line in that manifest. |

## Example

This report comes from a `puppet apply` run that created a file and evaluated a `notify` resource. Log
entries and resource statuses are trimmed for length, and an agent run would also include `server_used`:

```json
{
  "host": "web01.example.com",
  "time": "2026-07-20T06:16:41.086156000-04:00",
  "configuration_version": 1784542601,
  "transaction_uuid": "cf3624e9-744e-44d6-8c5c-057b812eb581",
  "report_format": 12,
  "puppet_version": "8.28.1",
  "status": "changed",
  "transaction_completed": true,
  "noop": false,
  "noop_pending": false,
  "environment": "production",
  "logs": [
    {
      "level": "notice",
      "message": "defined content as '{sha256}5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03'",
      "source": "/Stage[main]/Main/File[/etc/motd]/ensure",
      "tags": ["notice", "file", "class"],
      "time": "2026-07-20T06:16:41.087980000-04:00",
      "file": "/etc/puppetlabs/code/environments/production/manifests/site.pp",
      "line": 1
    },
    {
      "level": "notice",
      "message": "Applied catalog in 0.00 seconds",
      "source": "Puppet",
      "tags": ["notice"],
      "time": "2026-07-20T06:16:41.090383000-04:00",
      "file": null,
      "line": null
    }
  ],
  "metrics": {
    "resources": {
      "name": "resources",
      "label": "Resources",
      "values": [
        ["total", "Total", 9],
        ["skipped", "Skipped", 0],
        ["failed", "Failed", 0],
        ["failed_to_restart", "Failed to restart", 0],
        ["restarted", "Restarted", 0],
        ["changed", "Changed", 2],
        ["out_of_sync", "Out of sync", 2],
        ["scheduled", "Scheduled", 0],
        ["corrective_change", "Corrective change", 0]
      ]
    },
    "time": {
      "name": "time",
      "label": "Time",
      "values": [
        ["file", "File", 0.000751],
        ["notify", "Notify", 0.000333],
        ["config_retrieval", "Config retrieval", 0.071568],
        ["transaction_evaluation", "Transaction evaluation", 0.002611],
        ["catalog_application", "Catalog application", 0.004089],
        ["total", "Total", 0.004249]
      ]
    },
    "changes": {
      "name": "changes",
      "label": "Changes",
      "values": [
        ["total", "Total", 2]
      ]
    },
    "events": {
      "name": "events",
      "label": "Events",
      "values": [
        ["total", "Total", 2],
        ["failure", "Failure", 0],
        ["success", "Success", 2]
      ]
    }
  },
  "resource_statuses": {
    "File[/etc/motd]": {
      "title": "/etc/motd",
      "file": "/etc/puppetlabs/code/environments/production/manifests/site.pp",
      "line": 1,
      "resource": "File[/etc/motd]",
      "resource_type": "File",
      "provider_used": "posix",
      "containment_path": ["Stage[main]", "Main", "File[/etc/motd]"],
      "evaluation_time": 0.000751,
      "tags": ["file", "class"],
      "time": "2026-07-20T06:16:41.087274000-04:00",
      "failed": false,
      "failed_to_restart": false,
      "changed": true,
      "out_of_sync": true,
      "skipped": false,
      "change_count": 1,
      "out_of_sync_count": 1,
      "events": [
        {
          "audited": false,
          "property": "ensure",
          "previous_value": "absent",
          "desired_value": "file",
          "historical_value": null,
          "message": "defined content as '{sha256}5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03'",
          "name": "file_created",
          "status": "success",
          "time": "2026-07-20T06:16:41.087353000-04:00",
          "redacted": null,
          "corrective_change": false
        }
      ],
      "corrective_change": false
    }
  },
  "corrective_change": false,
  "catalog_uuid": "70898098-dd70-46af-a8a5-328fe921a5e9",
  "cached_catalog_status": "not_used"
}
```

To produce a report you can inspect yourself, run `puppet apply` with reporting enabled and read the YAML
that the `store` processor writes to [`reportdir`][reportdir]:

```console
puppet apply --report --reports=store manifest.pp
```
