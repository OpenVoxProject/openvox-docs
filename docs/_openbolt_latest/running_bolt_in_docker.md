---
layout: default
title: Run OpenBolt in a container
---

# Run OpenBolt in a container

The OpenVox project publishes a container image of OpenBolt, built from
[OpenVoxProject/container-openbolt](https://github.com/OpenVoxProject/container-openbolt).
Use it to run OpenBolt without installing a package, for example in a CI job.
The same image is available from two registries:

- `ghcr.io/openvoxproject/openbolt`
- `docker.io/voxpupuli/openbolt`

Images are built for `linux/amd64` and `linux/arm64`. The examples on this page
use Docker. Podman accepts the same commands, apart from the user mapping and
SELinux options in [File ownership on Linux](#file-ownership-on-linux).

## Choose an image tag

- `latest` is the newest image.
- `5.6.0-latest` is the newest build of OpenBolt 5.6.0. The image is rebuilt
  without changing the OpenBolt version, for example to pick up base image
  security fixes, so use this tag to pin OpenBolt.

```console
docker pull ghcr.io/openvoxproject/openbolt:5.6.0-latest
```

## How the image differs from the packages

- The image's entry point runs `bolt`, so everything after the image name is
  passed to OpenBolt. `docker run ghcr.io/openvoxproject/openbolt:5.6.0-latest --version`
  prints the OpenBolt version.
- OpenBolt runs as the `openbolt` user, with UID and GID `1001`, in the working
  directory `/data`. Mount your project at `/data`. On Linux, files you mount
  must be readable by that user; see [File ownership on Linux](#file-ownership-on-linux).
- The image installs OpenBolt as a gem, so it doesn't include the modules that
  the packages bundle, such as `facts`, `package`, and `service`. List the
  modules you need in your project and install them with `bolt module install`.
  The `facts` task also needs `puppetlabs-ruby_task_helper`, which you must list
  yourself.
- `apply_prep` and `apply` need the `openvox_bootstrap` module, which installs
  the OpenVox agent on targets. Without it, `apply_prep` fails with
  `Unknown plugin: 'openvox_bootstrap'`. Pin it to 1.4.0, the version the
  packages ship: newer releases, such as 1.6.0, install OpenVox 9 agents by
  default.

  ```yaml
  modules:
    - name: puppet-openvox_bootstrap
      version_requirement: 1.4.0
  ```

- For SSH key authentication, use an RSA private key in PEM format, which
  starts with `-----BEGIN RSA PRIVATE KEY-----`. Keys in the
  OpenSSH format, which `ssh-keygen` writes by default and which every ed25519
  key uses, fail with `OpenSSH keys only supported if ED25519 is available`.
  Use a password, or convert a copy of an RSA key to PEM format:

  ```console
  cp ~/.ssh/id_rsa keys/id_rsa
  ssh-keygen -p -m PEM -f keys/id_rsa
  ```

## Run a command

Run a command on the `localhost` target:

```console
$ docker run --rm ghcr.io/openvoxproject/openbolt:5.6.0-latest \
  command run 'cat /etc/os-release' --targets localhost
Started on localhost...
Finished on localhost:
  NAME="Alpine Linux"
  ID=alpine
  VERSION_ID=3.23.5
  PRETTY_NAME="Alpine Linux v3.23"
  HOME_URL="https://alpinelinux.org/"
  BUG_REPORT_URL="https://gitlab.alpinelinux.org/alpine/aports/-/issues"
Successful on 1 target: localhost
Ran on 1 target in 0.01 sec
```

The `localhost` target is the container, not the computer running Docker. To
run against other computers, give the container your inventory, either in an
environment variable or as part of a mounted project.

## Pass inventory in an environment variable

If you only need connection details, and no tasks or plans of your own, pass
the inventory in the `BOLT_INVENTORY` environment variable. This
`inventory.yaml` connects to one target with a password:

```yaml
targets:
  - name: web01
    uri: web01.example.com
    config:
      transport: ssh
      ssh:
        user: deploy
        password: secret-password
        host-key-check: false
```

Pass the file's contents when you start the container:

```console
$ docker run --rm --env "BOLT_INVENTORY=$(cat inventory.yaml)" \
  ghcr.io/openvoxproject/openbolt:5.6.0-latest \
  command run 'hostname' --targets web01
Started on web01...
Finished on web01:
  web01
Successful on 1 target: web01
Ran on 1 target in 0.22 sec
```

The inventory, including the password, appears in the `docker run` command line
and in `docker inspect` output for as long as the container exists.

## Mount a project

To use tasks, plans, and modules, mount an [OpenBolt project](projects.html) at
`/data`. This project has a task of its own and installs the `facts` module from
the Forge:

```console
$ tree
.
├── bolt-project.yaml
├── inventory.yaml
├── keys
│   └── id_rsa
└── modules
    └── docker_task
        └── tasks
            └── init.sh
```

**`bolt-project.yaml`**

```yaml
---
name: docker_example
modules:
  - name: puppetlabs-facts
  - name: puppetlabs-ruby_task_helper
```

**`inventory.yaml`**

The private key path is the path inside the container.

```yaml
targets:
  - name: web01
    uri: web01.example.com
    config:
      transport: ssh
      ssh:
        user: deploy
        private-key: /data/keys/id_rsa
        host-key-check: false
```

**`modules/docker_task/tasks/init.sh`**

```shell
#!/bin/sh
echo "Message: ${PT_message}"
```

Install the project's modules. OpenBolt writes `Puppetfile` and `.modules/`
into the mounted directory:

```console
$ docker run --rm --mount "type=bind,source=$PWD,target=/data" \
  ghcr.io/openvoxproject/openbolt:5.6.0-latest module install
Installing project modules

  → Resolving module dependencies, this might take a moment

  → Writing Puppetfile at /data/Puppetfile

  → Syncing modules from /data/Puppetfile to /data/.modules

  → Generating type references

Successfully synced modules from /data/Puppetfile to /data/.modules
```

Then run tasks from the project:

```console
$ docker run --rm --mount "type=bind,source=$PWD,target=/data" \
  ghcr.io/openvoxproject/openbolt:5.6.0-latest \
  task run docker_task message=hello --targets web01
Started on web01...
Finished on web01:
  Message: hello
Successful on 1 target: web01
Ran on 1 target in 0.4 sec
```

### File ownership on Linux

On Linux, a bind mount keeps the files' owner and permissions, and the
container's `openbolt` user (UID `1001`) is usually not you. A private key with
mode `0600` is then unreadable inside the container, and OpenBolt fails with
`The ssh key '/data/keys/id_rsa' is unreadable`. OpenBolt also can't write
`Puppetfile`, `.modules/`, or its log and rerun files into the project.

Run the container as your own user instead. Set `HOME` as well, because your
UID has no home directory in the image and installing modules needs one:

```console
docker run --rm --user "$(id -u):$(id -g)" --env HOME=/tmp \
  --mount "type=bind,source=$PWD,target=/data" \
  ghcr.io/openvoxproject/openbolt:5.6.0-latest \
  task run docker_task message=hello --targets web01
```

With rootless Podman, map your user to the image's user instead. Files that
OpenBolt creates are then owned by you on the host:

```console
podman run --rm --userns=keep-id:uid=1001,gid=1001 \
  --volume "$PWD:/data:Z" \
  ghcr.io/openvoxproject/openbolt:5.6.0-latest \
  task run docker_task message=hello --targets web01
```

The `:Z` suffix relabels the directory for SELinux. Docker Desktop on macOS maps
file ownership for you, so the default user works there without either option.

## Build an image on top

To ship a project and its modules in an image of their own, start from the
OpenBolt image. Put this `Containerfile` in the project directory:

```dockerfile
FROM ghcr.io/openvoxproject/openbolt:5.6.0-latest
COPY --chown=openbolt:openbolt . /data
RUN bundle exec bolt module install
```

Keep private keys out of the image with a `.dockerignore` file next to it:

```text
Containerfile
keys/
```

Build the image, then run it with the keys mounted read-only:

```console
docker build --tag my-openbolt --file Containerfile .
docker run --rm \
  --mount "type=bind,source=$PWD/keys,target=/data/keys,readonly" \
  my-openbolt task run facts --targets web01
```

The modules are installed at build time, so the container needs no network
access to the Forge when it runs. On Linux, the key file still has to be
readable inside the container; see [File ownership on Linux](#file-ownership-on-linux).
