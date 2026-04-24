---
layout: default
toc_levels: 1234
title: "OpenVox 8 known issues"
---

As known issues are discovered in OpenVox 8 and its patch releases, they'll be added to the [project's issue tracker](https://github.com/OpenVoxProject/openvox/issues). Once a known issue is resolved, it is listed as a resolved issue in the release notes for that release, and removed from this list.

## OpenVox 8.26.2

### `openvox --version` reports 8.26.1

After installing `openvox-agent` 8.26.2, running `puppet --version` reports `8.26.1` instead of `8.26.2`. The agent itself is at the correct version; only the version string returned by `--version` is incorrect. See [issue #415](https://github.com/OpenVoxProject/openvox/issues/415).
