---
layout: default
title: Getting started with OpenBolt
---

# Getting started with OpenBolt

Welcome to _Getting started with OpenBolt!_ OpenBolt is an open source orchestration
tool that helps you make on-demand changes to remote targets such as servers,
network devices, and cloud services.

In this guide, you'll write and run a plan. Plans are powerful
workflows that allow you to string together and automate commands, scripts,
tasks, and even other plans. Your plan will install Apache on a group
of target machines and upload a customized home page.

After you've completed this guide, you'll know how to:

- Set up an OpenBolt project directory.
- Run an OpenBolt command on a target.
- Create an inventory file to set up groups and add connection information for
  your targets.
- Write a plan that runs a bash script, runs a task, and uploads a
  file to your targets.

> **Before you begin**
>
>- Make sure you've installed OpenBolt on your machine. For instructions on how to
> install OpenBolt on your operating system, see [Installing
> OpenBolt](./bolt_installing.html).
>- Make sure you've [installed Docker](https://docs.docker.com/get-started/get-docker/)
> with the [Compose plugin](https://docs.docker.com/compose/install/), which
> provides the `docker compose` command.
> OpenBolt does not require Docker to run, but for the purposes of this guide,
> Docker containers offer a safe and relatively simple way to set up some
> targets to practice on.

## Create an OpenBolt project and set up targets

An OpenBolt project is a directory containing a `bolt-project.yaml` file. The
`bolt-project.yaml` file contains project-wide configuration settings. Your
`my_project` directory must contain a `bolt-project.yaml` file so OpenBolt
recognizes it as an OpenBolt project.

### Create an OpenBolt project directory

Create a directory named `my_project` and set it as your working directory:

```bash
mkdir my_project; cd my_project
```

Run the following command to turn `my_project` into an OpenBolt project:

_\*nix shell command:_

```console
bolt project init my_project
```

_Powershell cmdlet:_

```console
New-BoltProject -Name my_project
```

> **Note:** If your Powershell cmdlet doesn't work, make sure you've followed
> the steps to
> [install the PuppetBolt PowerShell module](bolt_installing.html#puppetbolt-powershell-module).

To use plans or tasks, your OpenBolt project must use a specific directory
structure. The directory structure of an OpenBolt project is closely tied to [Puppet
modules](/openvox/latest/modules_fundamentals.html).
Because your plan will install Apache, you need an `apache` module directory.
Your `apache` directory needs `files` and `plans` subdirectories.

Run the following commands to set up the required directories in your project
folder:

```bash
mkdir -p modules/apache/plans; mkdir -p modules/apache/files
```

After creating the directories, the file structure of `my_project` looks like this:

```bash
.
├── bolt-project.yaml
├── inventory.yaml
└── modules
    └── apache
        ├── files
        └── plans
```

Next, set up Docker targets to run Apache on.

### Create your targets

OpenBolt connects directly to computers, or _targets_, using Secure Shell (SSH) or
Windows Remote Management (WinRM). To see how a plan works, you'll build
and run some Docker containers to use as targets.

In the root of your `my_project` directory, create a file named `Dockerfile` and
paste in the following:

```dockerfile
FROM ubuntu:24.04
RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-server procps \
    && mkdir -p /run/sshd \
    && echo 'root:root' | chpasswd \
    && printf 'PermitRootLogin yes\n' > /etc/ssh/sshd_config.d/00-root.conf
EXPOSE 22 80
CMD ["/usr/sbin/sshd", "-D"]
```

This Dockerfile defines an Ubuntu 24.04 container with an active SSH service. The SSH
service allows OpenBolt to communicate with the container using the SSH transport.
The container lets `root` log in with the password `root`, so use it only for
practice. It also installs `procps` for the `ps` command, which a script uses
later in this guide.

> 🔩 **Tip**: A transport is the connection method that OpenBolt uses to
  connect and communicate with a target. There is a Docker transport that
  simplifies connecting to Docker containers, but the SSH transport is useful
  for gaining a broader understanding of how inventory files work.

Next, create a Compose file to run two instances of the
container. In your `my_project` directory, create the following file and name it
`compose.yaml`:

```yaml
services:
  target1:
    build: .
    ports:
      - '3000:80'
      - '2000:22'
    container_name: target1
  target2:
    build: .
    ports:
      - '3001:80'
      - '2001:22'
    container_name: target2
```

This compose file uses the Dockerfile to create two containers. The containers
are named `target1` and `target2`, and are bound to SSH ports `2000` and `2001`,
and HTTP ports `3000` and `3001`.

After creating your Dockerfile and `compose.yaml` file, your file
structure looks like this:

```bash
.
├── Dockerfile
├── bolt-project.yaml
├── compose.yaml
├── inventory.yaml
└── modules
    └── apache
        ├── files
        └── plans
```

Build and run your containers using the `docker compose` command:

```bash
docker compose up -d --build
```

You can check that your containers are running using the `docker compose ps`
command:

```bash
$ docker compose ps
NAME      IMAGE                COMMAND               SERVICE   CREATED          STATUS          PORTS
target1   my_project-target1   "/usr/sbin/sshd -D"   target1   10 seconds ago   Up 10 seconds   0.0.0.0:2000->22/tcp, [::]:2000->22/tcp, 0.0.0.0:3000->80/tcp, [::]:3000->80/tcp
target2   my_project-target2   "/usr/sbin/sshd -D"   target2   10 seconds ago   Up 10 seconds   0.0.0.0:2001->22/tcp, [::]:2001->22/tcp, 0.0.0.0:3001->80/tcp, [::]:3001->80/tcp
```

Your targets are ready. Next, run a command on a target to see how OpenBolt works.

## Run a command on a target

Before you start writing a plan, try using OpenBolt to run a command on one of your
targets. The syntax to run an OpenBolt command is `bolt command run <COMMAND>
--targets <TARGET_NAME> <OPTIONS>`.

Use the following command to run `whoami` on `target1`:

```bash
bolt command run whoami -t 127.0.0.1:2000 -u root -p root --no-host-key-check
```

This command targets `127.0.0.1:2000`, which is the IP address and SSH port for
the `target1` container. The command also specifies `root` as the username and
password, and includes the `--no-host-key-check` option to skip host key
verification.

After you run the command, you get the following output from `whoami`. Ignore
the warning about your inventory file. You'll set that up next.

```bash
$ bolt command run whoami -t 127.0.0.1:2000 -u root -p root --no-host-key-check
CLI arguments ["user", "password", "host-key-check"] might be overridden by Inventory: /home/user/my_project/inventory.yaml [ID: cli_overrides]
Started on 127.0.0.1:2000...
Finished on 127.0.0.1:2000:
  root
Successful on 1 target: 127.0.0.1:2000
Ran on 1 target in 0.21 sec
```

You've run your first OpenBolt command on a target! Next, create an inventory file
to group your targets together and simplify your OpenBolt commands.

## Create an inventory file to group your targets

You've just run a command on a single target. You could use the same command
with a comma-separated list to target both of your containers. However, as the
number of targets grows, this approach quickly becomes cumbersome. An inventory
file solves this problem.

With an inventory file, you can set up different connection settings for each of
your targets, and group targets together so you can aim a command at the group
instead of specifying targets in a list.

When you set up your OpenBolt project, OpenBolt created an inventory file template named
`inventory.yaml` in your project directory. Replace the contents of that file
with the following:

```yaml
groups:
- name: containers
  targets:
    - uri: 127.0.0.1:2000
      name: target1
    - uri: 127.0.0.1:2001
      name: target2
  config:
    transport: ssh
    ssh:
      user: root
      password: root
      host-key-check: false
```

This inventory file contains a group called `containers`. The `containers` group
lists:

- The Uniform Resource Identifier (URI) and name for each Docker container.
- The transport type that OpenBolt is using to communicate with the containers. In
  this case you're using the SSH transport.
- The SSH authentication settings, which include the username, password, and
  whether OpenBolt should check for host keys.

To test your inventory file, run the `whoami` command on `target1`:

```bash
bolt command run whoami -t target1
```

Notice how much shorter the command is now that the inventory file is handling
connection details like the user, password, ports, and URIs.

To run the command on both containers in the `containers` group:

```bash
bolt command run whoami -t containers
```

To run the command on all targets in an inventory, use OpenBolt's implicit `all`
group:

```bash
bolt command run whoami -t all
```

Next, write a plan to install Apache on your targets.

## Write a plan

Plans allow you to tie your commands, scripts, and tasks together to create
powerful workflows. You can write plans in the Puppet language, or use
YAML. In this guide, you're going to write a YAML plan that installs the Apache
package on your Docker targets, starts the Apache service, and uploads an HTML
homepage.

### Use a task to install Apache on your targets

The first step in your YAML plan uses a Puppet task to install Apache on your
targets.

In your `my_project/modules/apache/plans` directory, create the following
file and name it `install.yaml`:

```yaml
parameters:
  targets:
    type: TargetSpec

steps:
  - name: install_apache
    task: package
    targets: $targets
    parameters:
      action: install
      name: apache2
    description: "Install Apache using the package task"
```

The first section of a plan defines the parameters your plan accepts. So
far, this plan has one parameter, `targets`, with the type `TargetSpec`. The
`TargetSpec` type is a wrapper for defining targets that allows you to pass a
target, or multiple targets, into a plan. When you run this plan from the
command line and use the `--targets` argument, OpenBolt interpolates the targets
into the `targets` parameter.

After the `parameters` section, you define the steps that make up the body of
your plan. The first step in your plan is named `install_apache`. This step uses
a task called `package` to install Apache on your targets. The `package`
task includes:

- A `targets` parameter so OpenBolt knows which targets to execute the step on: In
  this case the task is using the `$targets` parameter, so the step will run on
  all of the targets that you specify when you run your plan.
- A `parameters` section to tell the task what action to perform (`install`),
  and the name of the package that OpenBolt should install (`apache2`).
- An optional `description` key.

> 🔩 **Tip**: A task is a script that has been packaged into a Puppet
module. The `package` task comes prepackaged with OpenBolt and allows you to perform
various package-related actions. Tasks are useful because you can reuse
them or share them with others. Many of the modules on the [Puppet
forge](https://forge.puppet.com/modules?with_tasks=true) include tasks.

After creating `install.yaml`, your file structure looks like this:

```bash
.
├── Dockerfile
├── bolt-project.yaml
├── compose.yaml
├── inventory.yaml
└── modules
    └── apache
        ├── files
        └── plans
            └── install.yaml
```

From the root of your project directory, run the plan on your containers group
using the following command:

```bash
bolt plan run apache::install -t containers
```

> **Note**: The name of this plan consists of two segments joined by a double
  colon. The first segment indicates the name of the module where the plan is
  located and the second segment is the name of the plan file without the
  extension. Your plan is located in the `apache` module directory and is named
  `install.yaml`, so the name of the plan is `apache::install`.

The output looks like this:

```bash
$ bolt plan run apache::install -t containers
Starting: plan apache::install
Starting: Install Apache using the package task on target1, target2
Finished: Install Apache using the package task with 0 failures in 9.73 sec
Finished: plan apache::install in 9.73 sec
Plan completed successfully with no result
```

Next, run a script on your targets to start the Apache service.

### Run a script on your targets

Because you're running Apache on containers, the Apache service does not start
automatically. You must create a short bash script that starts the Apache
service and add it to your plan as a script step.

Create a file named `start_apache.sh` in `my_project/modules/apache/files/`
and enter the following script:

```bash
#!/usr/bin/env bash

i=`ps -eaf | grep -i apache | grep -v grep | grep -v bash | wc -l`

if [[ $i > 0 ]]
then
  echo "Apache is running"
else
  echo "Starting Apache"
  apache2ctl start
fi
```

At this point, your file structure looks like this:

```bash
.
├── Dockerfile
├── bolt-project.yaml
├── compose.yaml
├── inventory.yaml
└── modules
    └── apache
        ├── files
        │   └── start_apache.sh
        └── plans
            └── install.yaml
```

The script checks the processes running on the container for Apache and starts
the service if it is not running.

Now, add the script to `install.yaml` as a step. After the `install_apache`
step, paste the following:

```yaml
- name: start_apache
  script: apache/start_apache.sh
  targets: $targets
  description: "Start the Apache service"
```

The step calls the `start_apache.sh` script from your apache module directory.
Because the file is in your `<MODULE_NAME>/files` location, you can use the
syntax `<MODULE_NAME>/<FILE_NAME>` instead of typing out the full path to the
script.

Your plan now looks like this:

```yaml
parameters:
  targets:
    type: TargetSpec

steps:
  - name: install_apache
    task: package
    targets: $targets
    parameters:
      action: install
      name: apache2
    description: "Install Apache using the package task"

  - name: start_apache
    script: apache/start_apache.sh
    targets: $targets
    description: "Start the Apache service"
```

Run the plan again:

```bash
bolt plan run apache::install -t containers
```

At this point, you can reach either of your targets in your web browser at
`127.0.0.1` on port `3000` for `target1`, or port `3001` for `target2`.
Go to [127.0.0.1:3000](http://127.0.0.1:3000) to see Apache's default Ubuntu
homepage on `target1`.

You have two functioning Apache servers. Next, upload a file to your targets to
change the homepage.

### Upload an HTML homepage to your targets

Now that Apache is installed on both of your containers, upload an HTML homepage
for the targets to display.

In `my_project/modules/apache/files/`, create a file named `index.html` and
enter the following:

```html
<html>
  <head>
    <title> Getting started with OpenBolt </title>
  </head>
  <body>
    <h1>Success!</h1>
    <p>I'm running this website on a server configured with OpenBolt!</p>
  </body>
</html>
```

Your final file structure looks like this:

```bash
.
├── Dockerfile
├── bolt-project.yaml
├── compose.yaml
├── inventory.yaml
└── modules
    └── apache
        ├── files
        │   ├── index.html
        │   └── start_apache.sh
        └── plans
            └── install.yaml
```

Before you add a step to upload your homepage to your containers, you must
define another parameter. In the `parameters` section of `install.yaml`, add a
parameter named `src` with the type `String`. The `src` parameter is the
location of the file you want to upload. You'll pass in `src` as an argument
when you run the plan.

The `parameters` section of your plan now looks like this:

```yaml
parameters:
  targets:
    type: TargetSpec
  src:
    type: String
...
```

Now add the following step after the `start_apache` step:

```yaml
- name: upload_homepage
  upload: $src
  destination: /var/www/html/index.html
  targets: $targets
  description: "Upload homepage"
```

The `upload_homepage` step uploads a file from the path you specify to a
destination path on the specified targets.

Your final plan looks like this:

```yaml
parameters:
  targets:
    type: TargetSpec
  src:
    type: String

steps:
  - name: install_apache
    task: package
    targets: $targets
    parameters:
      action: install
      name: apache2
    description: "Install Apache using the package task"

  - name: start_apache
    script: apache/start_apache.sh
    targets: $targets
    description: "Start the Apache service"

  - name: upload_homepage
    upload: $src
    destination: /var/www/html/index.html
    targets: $targets
    description: "Upload homepage"
```

This time, run the plan with the `src` argument to give OpenBolt a path to the
homepage file you want to upload:

```bash
bolt plan run apache::install -t containers src=apache/index.html
```

> **Remember**: Because the file is in your `<MODULE_NAME>/files` location, you
  can use the syntax `src=<MODULE_NAME>/<FILE_NAME>` instead of typing in the
  full path to the file.

Go to [127.0.0.1:3000](http://127.0.0.1:3000) again to see your new index page.

> **Note**: If the page hasn't changed from the default Ubuntu homepage, try a
  hard refresh to clear the page's cache. On most browsers, you can accomplish
  this by holding **Shift** and clicking **Reload**.

Congratulations! You've learned how to run commands and scripts with OpenBolt,
you've created an OpenBolt project with an inventory file, and you've written and run
a plan that installs Apache on your targets and uploads a customized
homepage.

**Continue learning about OpenBolt:**

- For more information on working with Windows targets, see [Automating Windows
  targets](automating_windows_targets.html).
- To find out more about plans, see [Orchestrating workflows with
  plans](./plans.html).
- For a list of available OpenBolt transports, see [Running OpenBolt
  commands](./running_bolt_commands.html).
- To learn about tasks, see [Making on-demand changes with
  tasks](./tasks.html).
- To find Puppet modules that use tasks, take a look at the [Puppet
  Forge](https://forge.puppet.com/).
- For information on OpenBolt configuration see [Configuring OpenBolt](configuring_bolt.html).
- For information on OpenBolt projects see [OpenBolt projects](projects.html)
