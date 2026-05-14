---
layout: default
title: "OpenVox Containers"
---

The [VoxPupuli](https://github.com/voxpupuli) and [OpenVoxProjekt](https://github.com/openvoxProject/) communities offer several different types of containers.

## OpenVox infrastructure

The individual usage is not describe in this documentation.
The general descriptions mentioned in this documentation are still valid, but differs in implementation due to the nature of container.
Individual configuration options must be taken from each of the repositories.

The following containers exist:

- [OpenVox Server](https://github.com/OpenVoxProject/container-openvoxserver)
- [OpenVox DB](https://github.com/OpenVoxProject/container-openvoxdb)
- [OpenBolt](https://github.com/OpenVoxProject/container-openbolt)

## Deployment

There are two repositories which provide examples to deploy containers:

- [CRAFTY](https://github.com/voxpupuli/crafty) - Examples for Docker/Podman compose
- [Helm Chart](https://github.com/OpenVoxProject/openvox-helm-chart) - Examples for K8s Helm based deployments

## Reporting Web UI

Next to OpenVox infrastructure there are also containers for a reporting Web UI:

- [PuppetBoard](https://github.com/voxpupuli/puppetboard)
- [OpenVoxView](https://github.com/voxpupuli/openvoxview)

## CI/CD

Besides this there are a number of containers which can be used in CI/CD:

- [VoxBox](https://github.com/voxpupuli/container-voxbox)
- [Onceover](https://github.com/voxpupuli/container-onceover)
- [Commitlint](https://github.com/voxpupuli/container-commitlint)
- [R10k](https://github.com/voxpupuli/container-r10k)
- [R10k-Webhook](https://github.com/voxpupuli/container-r10k-webhook)
- [Renovate](https://github.com/voxpupuli/container-renovate)
- [Semantic Release](https://github.com/voxpupuli/container-semantic-release)
