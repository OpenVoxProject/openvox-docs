---
layout: default
title: "Quick Start » Creating users and groups"
subtitle: "Users and groups quick start guide"
---

## Before you begin

> **Prerequisites**: This guide assumes you've already [installed Puppet](/openvox-server/latest/install_from_packages.html), and have installed at least one [*nix agent](./install_linux.html).
>
> For this  walk-through, log in as root or administrator on your nodes.

## Create a user and group

Puppet uses some defaults for unspecified user and group attributes, so all you'll need to do to create a new user and group is set the 'ensure' attribute to 'present'. This 'present' value tells Puppet to check if the resource exists on the system, and to create the specified resource if it does not.

1. To create a user named `jargyle`, on your OpenVox Server, run `puppet apply -e "user { 'jargyle': ensure => present, }"`. The result should show, in part, `Notice: /Stage[main]/Main/User[jargyle]/ensure: created`.

2. To create a group named `web`, on your OpenVox Server, run `puppet apply -e "group { 'web': ensure => present, }"`. The result should show, in part, `Notice: /Stage[main]/Main/Group[web]/ensure: created`.

> That's it! You've successfully created the Puppet user `jargyle` and the Puppet group `web`.

## Add the group to the main manifest

1. From the command line on your OpenVox Server, run `puppet resource -e group web`. This opens a file in your text editor with the following content:

   ```puppet
   group { 'web':
       ensure => 'present',
       gid    => '502',
   }
   ```

   >**Note**: Your gid (the group ID) might be a different number than the example shown in this guide.

2. Copy the lines of code, and save and exit the file.

3. Navigate to your main manifest: `cd /etc/puppetlabs/code/environments/production/manifests`.

4. Still using the OpenVox Server, paste the code you got from Steps 1 and 2 into the default node `site.pp`, then save and exit.

5. From the command line on your OpenVox Server, run `puppet parser validate site.pp` to ensure that there are no errors. The parser will return nothing if there are no errors.

6. From the command line on your OpenVox agent, use `puppet agent -t` to trigger a Puppet run.

> That's it! You've successfully added your group, `web`, to the main manifest.

## Add the user to the main manifest

1. From the command line on your OpenVox Server, run `puppet resource -e user jargyle`. This opens a file in your text editor with the following content:

   ```puppet
   user { 'jargyle':
      ensure           => 'present',
     gid              => '501',
     home             => '/home/jargyle',
     password         => '!!',
     password_max_age => '99999',
     password_min_age => '0',
     shell            => '/bin/bash',
     uid              => '501',
   }
   ```

   >**Note**: Your uid (the user ID), or gid (the group ID) might be different numbers than the examples shown in this guide.

2. Add the following Puppet code to the file:

   ```puppet
   comment           => 'Judy Argyle',
   groups            => 'web',
   ```

3. **Delete** the following Puppet code from the file:

   ```puppet
   gid              => '501',
   ```

4. Copy all of the code, and save and exit the file.

5. Paste the code from Step 1 into your default node in `site.pp`. It should look like this:

   ```puppet
   user { 'jargyle':
      ensure           => 'present',
     gid              => '501',
     home             => '/home/jargyle',
     comment           => 'Judy Argyle',
     groups            => 'web',
     password         => '!!',
     password_max_age => '99999',
     password_min_age => '0',
     shell            => '/bin/bash',
     uid              => '501',
   }
   ```

6. From the command line on your OpenVox Server, run `puppet parser validate site.pp` to ensure that there are no errors. The parser will return nothing if there are no errors.

7. From the command line on your OpenVox agent, use `puppet agent -t` to trigger a Puppet run.

> Success! You have created a user, `jargyle`, and added jargyle to the group with `groups => web`.
> For more information on users and groups, check out the documentation for Puppet resource types regarding [users](./types/user.html) and [groups](./types/group.html).
> With users and groups, you can assign different permissions for managing Puppet.

---------
Next: [Hello, world!](./quick_start_helloworld.html)
