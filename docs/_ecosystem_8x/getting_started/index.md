---
layout: default
title: "Getting Started with OpenVox"
---

So you want to manage infrastructure with code?
Excellent life choice.

Whether you're setting up 3 servers or 3,000, OpenVox has your back.
This guide will take you from zero to "Hey, it actually works!" in about 30 minutes.
It's designed to be a whirlwind through the ecosystem, and when you're ready for more information you can move on to the more complete docs.

**What you'll learn:**

* [Installing OpenVox](#installation)
* [Your first manifest](#your-first-manifest)
* [Understanding what just happened](#understanding-the-magic)
* [Where to go next](#next-steps)


## Prerequisites

Before we dive in, you'll need:

* A machine to run OpenVox on
* Root or `sudo` access
* Internet connectivity (to reach the package repos)
* A healthy sense of adventure

OpenVox supports macOS, Windows, SLES, Amazon Linux, and other platforms.
This guide focuses on the RHEL/Debian families because that's where most of the action is.
{: .tip }


## Installation

Linux is the platform for OpenVox **servers**, but agents run on plenty of other platforms.
Windows and macOS installers are distributed as manually installable MSI/PKG files.

The official [Installing OpenVox](https://voxpupuli.org/openvox/install/) guide has step-by-step instructions for each platform.

For this part of the guide, you'll only need to install the OpenVox Agent, but for other use cases you might want other packages.
See the [platform docs](/openvox/latest/openvox_platform.html) for more information.

The OpenVox agent installs into `/opt/puppetlabs/`.
The binary lives at `/opt/puppetlabs/bin/puppet`.
The installer adds `/opt/puppetlabs/bin` to your `PATH`.
If you're in a weird shell, source your profile or use the full path.
For convenience, you can also add `/opt/puppetlabs/puppet/bin` to `PATH` in `/etc/profile.d/puppet.sh` so internal tools like `gem`, `bundle`, and `r10k` are available."
{: .tip }


## Your First Manifest

Let's write some infrastructure-as-code! A **manifest** is a file (ending in `.pp`) that describes the desired state of your system using the Puppet language.

### Hello, OpenVox

Create a file called `hello.pp`:

```puppet
# hello.pp — Your first OpenVox manifest!

# This ensures a file exists with specific content
file { '/tmp/hello-openvox.txt':
  ensure  => file,
  content => "Hello from OpenVox! 🦊\nManaged by Puppet DSL.\n",
  mode    => '0644',
}

# Let's also make sure a useful package is installed
package { 'tree':
  ensure => installed,
}

# And print a friendly notification
notify { 'welcome_message':
  message => 'OpenVox is now managing this system. Resistance is futile (but also unnecessary).',
}
```

### Apply It

```console
$ sudo puppet apply hello.pp
Notice: Compiled catalog for example.com in environment production in 0.18 seconds
Notice: /Stage[main]/Main/File[/tmp/hello-openvox.txt]/ensure: defined content as '{sha256}7a8b9c...'
Notice: /Stage[main]/Main/Package[tree]/ensure: created
Notice: OpenVox is now managing this system. Resistance is futile (but also unnecessary).
Notice: Applied catalog in 2.55 seconds
```

Always use `sudo puppet apply` when running manifests that affect system state.
Running as `root` (or via sudo) ensures Puppet can manage all resources, including system packages, services, and protected files.
For development and testing, you can run as a non-privileged user, but many resource types will fail or behave unexpectedly.
{: .tip }


### Verify It Worked

```console
$ cat /tmp/hello-openvox.txt
Hello from OpenVox! 🦊
Managed by Puppet DSL.
```

```console
$ which tree
/usr/bin/tree
```

🎉 **Congratulations!** You just used infrastructure-as-code to manage your system's state.
The file was created, the package was installed, and the notification was printed.
If you run `puppet apply hello.pp` again, nothing will change — because the system already matches the desired state.
That's **idempotence**, and it's the secret sauce of configuration management.

### Experiment with idempotence

Idempotence is a nerdy mathematical theory defining an operation that has the same result no matter how many times it runs.
For example, multiplying by one or zero are both idempotent: `n*1*1*1*1.....*1` still equals `n` and `n*0*0*0*0.....*0` still equals `0`.
OpenVox works in similar ways; when you describe the state you want, it will identify what needs to be done to put the system in that state and then do it.
That means that unlike a shell script which might or might not have strange behaviours when run again,
OpenVox is designed to regularly enforce the state you want and you don't have to worry about intermediate states.

In other words, it doesn't blindly execute commands — it checks the current state, compares it to the desired state, and only makes changes when something is out of spec.

Let's try it out and enforce your manifest again.
Notice that the only output you get is the notice and no system resources are changed.


```console
$ sudo puppet apply hello.pp
Notice: Compiled catalog for example.com in environment production in 0.18 seconds
Notice: OpenVox is now managing this system. Resistance is futile (but also unnecessary).
Notice: Applied catalog in 2.55 seconds
```

No matter how many times you run it, you'll get the same results.
Now try changing a few words in `/tmp/hello-openvox.txt` and enforcing your state again:

```console
$ vim /tmp/hello-openvox.txt
$ sudo puppet apply hello.pp
Notice: Compiled catalog for example.com in environment production in 0.18 seconds
Notice: /Stage[main]/Main/File[/tmp/hello-openvox.txt]/content: content changed '{sha256}0d6751dde6d6b9c4839dcc616eeb3a7259a5a56328b890b895ddf7771bd3619e' to '{sha256}b37a0d63d02bee28d2bbcfec5f7031a25cbe26b0cb5f6d34bbb288a3fbb13117'
Notice: OpenVox is now managing this system. Resistance is futile (but also unnecessary).
Notice: Applied catalog in 2.55 seconds
```

This is the beauty of a ***declarative*** and ***idempotent*** system for configuration management.
Just describe clearly what you want and let OpenVox enforce it.


## Understanding the Magic

Let's break down what just happened:

### Resources

Everything in Puppet/OpenVox is a **resource**. A resource is a single unit of configuration — a file, a package, a service, a user, a cron job. Each resource has:

* A **type** (what kind of thing: `file`, `package`, `service`, etc.)
* A **title** (identifies the resource — often the thing itself, like a file path)
* **Attributes** (the desired properties: `ensure`, `content`, `mode`, etc.)

```puppet
# Anatomy of a resource
type { 'title':
  attribute => value,
  another   => value,
}
```

#### A Word About Titles

The title serves double duty. Most of the time, the title **is** the resource you're managing — the file path, the package name, or the service name:

```puppet
# The title IS the file path — clean and simple
file { '/tmp/hello-openvox.txt':
  ensure  => file,
  content => "Hello!\n",
}
```

But sometimes you want a descriptive title instead. When you do that, you **must** explicitly specify the resource's identity using the appropriate parameter (`path` for files, `name` for packages/services, etc.):

```puppet
# Descriptive title — must include 'path' to tell Puppet which file
file { 'hello_file':
  ensure  => file,
  path    => '/tmp/hello-openvox.txt',
  content => "Hello!\n",
}
```

Both forms manage the exact same file.
The first is shorthand; the second is more readable when the path is long or you want the title to describe *intent* rather than *location*.
For a deeper dive into this, see [the language reference](/openvox/latest/lang_resources.html#namenamevar).

### The Catalog

When you run `puppet apply`, the Puppet compiler reads your manifest and builds a **catalog** — a complete description of all the resources and their relationships.
The catalog is then applied to the system.
Think of it as a blueprint: Puppet reads the blueprint, looks at the building, and fixes anything that doesn't match.

## Next Steps

* Using `puppet apply` is great for standalone work, but the real power of OpenVox comes from managing an entire infrastructure just as easily. [Learn about setting up an OpenVox Server](agent-server.html).
* Maybe you'd rather learn more about the language first. Check out the [Puppet Language Intro](language.html).
