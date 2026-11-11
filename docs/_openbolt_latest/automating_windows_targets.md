---
layout: default
title: Automating Windows targets
---

# Automating Windows targets

Here are some common use cases that you can accomplish with OpenBolt on Windows targets.

## Run a PowerShell script that restarts a service

To show you how you can use OpenBolt to reuse your existing PowerShell scripts, this
guide walks you through running a script with OpenBolt, and then converting the
script to a task and running that.

> **Before you begin**
>
> - Ensure you’ve already [installed OpenBolt](bolt_installing.html) on your
>     Windows machine.
> - Identify a remote Windows target to work with.
> - Ensure you have Windows credentials for the target.
> - Ensure you have [configured Windows Remote
>     Management](https://learn.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management)
>     on the target. OpenBolt connects over HTTPS on port 5986 and verifies the
>     target's certificate by default.
> - Ensure the target's [PowerShell execution
>     policy](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)
>     allows scripts to run, for example `RemoteSigned`. Windows Server uses
>     `RemoteSigned` by default, but Windows client editions such as Windows 11
>     use `Restricted`, and OpenBolt can't run scripts or tasks on a target
>     with that policy.

The example script, `restart_service.ps1`, performs a common task: restarting a
service on demand. The process involves these steps:

1. Run your PowerShell script on a Windows target.
1. Create an inventory file to store information about the target.
1. Convert your script to a task.
1. Execute your new task.


### 1. Run your PowerShell script on a Windows target

First, we’ll use OpenBolt to run the script as-is on a single target.

1. Create a directory to work in, called `bolt-guide`.
1. In `bolt-guide`, create a file named `restart_service.ps1` with the
    following content:

    ```powershell
    [CmdletBinding()]
    param (
      # Name or list of service names to stop
      [Parameter(Mandatory=$true)]
      [string[]]
      $service,
      # Stop the services without starting them again
      [Parameter(Mandatory=$false)]
      [switch]
      $norestart
    )

    foreach ($name in $service) {
      try{
        $serviceObject = Get-service -Name $name -ErrorAction SilentlyContinue

        if(-not $serviceObject){
          Write-Output "Service not found: $name"
          continue
        }

        Write-output "Found Service: $name"

        Stop-Service -InputObject $serviceObject -ErrorAction Stop

        Write-Output "Stopped service: $name"

        if($norestart){continue}

        Start-Service -InputObject $serviceObject

        Write-Output "Started service: $name"

      } catch {
        Write-Output "Cannot stop service: $name"
        Write-Output "Dependent services: $($serviceObject.dependentservices)"

        exit 1
      }
    }
    ```

1. In the `bolt-guide` directory, run the `restart_service.ps1` script:

    ```console
    bolt script run .\restart_service.ps1 W32Time --targets winrm://<HOSTNAME> -u Administrator --password-prompt
    ```

    The output looks like this:

    ```console
    Started on winrm://win01.example.com...
    Finished on winrm://win01.example.com:
      Found Service: W32Time
      Stopped service: W32Time
      Started service: W32Time
    Successful on 1 target: winrm://win01.example.com
    Ran on 1 target in 6.62 sec
    ```

    **Note:** The `--password-prompt` option prompts you to enter a password.

    By running this command, you’ve brought your script under OpenBolt control and
    have run it on a remote target. When you ran your script with OpenBolt, the
    script was transferred into a temporary directory on the remote target, it
    ran on that target, and then it was deleted from the target.


### 2. Create an inventory file to store information about your targets

To run OpenBolt commands against multiple targets at once, you need to provide
information about the environment by creating an [inventory
file](inventory_files.html). The inventory file is a YAML file that contains a
list of targets and target specific data.

1. Inside the `bolt-guide` directory, use a text editor to create an
    `inventory.yaml` file and a `bolt-project.yaml` file. The `inventory.yaml` file is where
    connection information is stored, while `bolt-project.yaml` tells OpenBolt that the directory is a project
    and that it should load the inventory file from the directory.
1. Inside the new `inventory.yaml` file, add the following content, listing the
    fully qualified domain names of the targets you want to run the script on,
    and replacing the credentials in the `winrm` section with those appropriate
    for your target:

    ```yaml
    groups:
      - name: windows
        targets:
          - <ADD WINDOWS SERVERS' FQDN>
          - <example.mycompany.com>
        config:
          transport: winrm
          winrm:
            user: Administrator
            password: <ADD PASSWORD>
            # cacert: <PATH TO CA CERTIFICATE>
            # ssl-verify: false
    ```

    If the target's WinRM certificate is self-signed or signed by a private
    certificate authority, OpenBolt can't verify it and fails to connect. Either
    uncomment `cacert` and set it to the path of the CA certificate, or, for a
    test target, uncomment `ssl-verify: false`. On the command line, the
    equivalent of `ssl-verify: false` is `--no-ssl-verify`.

    **Note:** To have OpenBolt securely prompt for a password, use the
    `--password-prompt` command-line option without supplying any value. This
    prevents the password from appearing in a process listing or on the console.
    Alternatively you can use the [`prompt` plugin](supported_plugins.html#prompt) to
    set configuration values via a prompt.

    You now have an inventory file where you can store information about your
    targets.

    You can also configure a variety of options for OpenBolt in `bolt-project.yaml`. For more
    information about configuration see [Configuring OpenBolt](configuring_bolt.html). For more
    information about OpenBolt projects see [OpenBolt projects](projects.html).


### 3. Convert your script to a task

To convert the `restart_service.ps1` script to a task, giving you the ability to
reuse and share it, create a [task metadata](writing_tasks.html) file. Task
metadata files describe task parameters, validate input, and control how the
task runner executes the task.

**Note:** This guide shows you how to convert the script to a task by manually
creating the metadata file in a directory called `tasks`. If your task lives in
a module created with [Jig](/ecosystem/latest/devkit/jig.html), `jig new task
<name>` creates the metadata file for you.

1. In the `bolt-guide` directory, create the following subdirectories:

    ```text
    bolt-guide/
    └── modules
        └── gsg
            └── tasks
    ```

1. Move the `restart_service.ps1` script into the `tasks` directory.
1. In the `tasks` directory, use your text editor to create a task metadata
    file — named after the script, but with a `.json` extension, in this
    example, `restart_service.json`.
1. Add the following content to the new task metadata file:

    ```json
    {
      "puppet_task_version": 1,
      "supports_noop": false,
      "description": "Stop or restart a service or list of services on a target.",
      "parameters": {
        "service": {
          "description": "The name of the service, or a list of service names to stop.",
          "type": "Variant[Array[String],String]"
        },
        "norestart": {
          "description": "Stop the services without starting them again.",
          "type": "Optional[Boolean]"
        }
      }
    }
    ```

1. Save the task metadata file and navigate back to the `bolt-guide` directory.

    You now have two files in the `gsg` module’s `tasks` directory:
    `restart_service.ps1` and `restart_service.json` -- the script is officially
    converted to a task. Now that it’s converted, you no longer need to
    specify the file extension when you call it from an OpenBolt command.
1. Validate that OpenBolt recognizes the script as a task:

    ```console
    bolt task show gsg::restart_service
    ```

    ```console
    gsg::restart_service
      Stop or restart a service or list of services on a target.

    Usage
      bolt task run gsg::restart_service --targets <targets> [norestart=<value>]
      service=<value>

    Parameters
      norestart  Optional[Boolean]
        Stop the services without starting them again.

      service  Variant[Array[String],String]
        The name of the service, or a list of service names to stop.

    Module
      C:/Users/user/bolt-guide/modules/gsg
    ```

    Congratulations! You’ve successfully converted the `restart_service.ps1`
    script to a task.

1. Execute your new task:

    ```console
    bolt task run gsg::restart_service service=W32Time --targets windows
    ```

    ```console
    Started on win01.example.com...
    Finished on win01.example.com:
      Found Service: W32Time
      Stopped service: W32Time
      Started service: W32Time
    Successful on 1 target: win01.example.com
    Ran on 1 target in 4.24 sec
    ```

    **Note:** `--targets windows` refers to the name of the group of targets
    that you specified in your inventory file. For more information, see
    [Specify targets](running_bolt_commands.html).

## Deploy a package with OpenBolt and Chocolatey

You can use OpenBolt with Chocolatey to deploy a package on a Windows target. First,
use the `apply` command to install Chocolatey on the target. Next, use the
built-in `package` task, which installs packages with Chocolatey on Windows
targets.

This example installs the `jq` package on a Windows target.

**Before you begin:**

- [Install OpenBolt](bolt_installing.html)
- Configure Windows Remote Management (WinRM) on your Windows target.
- If the target's WinRM certificate is self-signed, add `--no-ssl-verify` to
  the commands below, or `-SslVerify:$false` to the PowerShell cmdlets.

To install the `jq` package with Chocolatey:

1. Install the Chocolatey module to your OpenBolt project. This allows you to
   install Chocolatey to your target in the next step.
   - If you're using an existing OpenBolt project:

      _\*nix shell command:_

      ```console
      bolt module add puppetlabs-chocolatey
      ```

      _PowerShell cmdlet:_

      ```powershell
      Add-BoltModule -Module puppetlabs-chocolatey
      ```

   - If you want to create a project (named `choco_project`) that includes the Chocolatey module. Create a directory named `choco_project` and run the following command inside the directory:

      _\*nix shell command:_

      ```console
      bolt project init choco_project --modules puppetlabs-chocolatey
      ```

      _PowerShell cmdlet:_

      ```powershell
      New-BoltProject -Name choco_project -Modules puppetlabs-chocolatey
      ```

1. Install Chocolatey on your Windows target using the `apply` command:

   _\*nix shell command:_

    ```console
    bolt apply -e 'include chocolatey' -t <TARGET URI> -u <USER> -p <PASSWORD> --transport winrm
    ```

    _PowerShell cmdlet:_

    ```powershell
    Invoke-BoltApply -Execute "include chocolatey"  -Targets <TARGET URI> -User <USER> -Password <PASSWORD> -Transport winrm
    ```

1. Use the built-in `package` task to install `jq` on your target:

    _\*nix shell command:_

    ```console
    bolt task run package -t <TARGET URI> -u <USER> -p <PASSWORD> --transport winrm action=install name=jq
    ```

    _PowerShell cmdlet:_

    ```powershell
    Invoke-BoltTask -Name package -Targets <TARGET URI> -User <USER> -Password <PASSWORD> -Transport winrm action=install name=jq
    ```

1. Run `jq` on your target to test:

   _\*nix shell command:_

   ```console
   bolt command run 'jq --version' -t <TARGET URI> -u <USER> -p <PASSWORD> --transport winrm
   ```

   _PowerShell cmdlet:_

   ```powershell
   Invoke-BoltCommand 'jq --version' -Targets <TARGET URI> -User <USER> -Password <PASSWORD> -Transport winrm
   ```

   Your output should look something like this:

   ```console
   Started on win01.example.com...
   Finished on win01.example.com:
     jq-1.8.2
   Successful on 1 target: win01.example.com
   Ran on 1 target in 2.26 sec
   ```

If you need to install packages on multiple targets, create an OpenBolt project with
an inventory for your targets. Using an inventory allows you to group your
targets together and dramatically simplifies OpenBolt commands.

📖 **Related information**

- [OpenBolt projects](projects.html)
- [Inventory files](inventory_files.html)
- [Applying Puppet code](applying_manifest_blocks.html)

Do you have a real-world use case for OpenBolt that you'd like to share? Tell us
about it in the [OpenVox community](/ecosystem/latest/community.html).
