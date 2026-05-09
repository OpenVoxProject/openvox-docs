---
layout: default
title: "Puppet Language Intro"
---

> *"It's not programming, it's declaring your intentions to the universe. The universe just happens to be made of servers."*


## Overview

The Puppet language (also called the Puppet DSL) is a **declarative, domain-specific language** designed for one thing: describing the desired state of your infrastructure.
You don't tell Puppet *how* to do something — you tell it *what you want*, and it figures out the rest.

If you're coming from scripting of any kind, this requires a small shift in thinking.
Instead of writing:

```bash
# Imperative (shell): HOW to do it
source /etc/os-release
if $ID == 'rhel'; then
  if ! rpm -q httpd; then
    yum install -y httpd
  fi
  systemctl enable httpd
  systemctl start httpd
elsif $ID == 'ubuntu'; then
  if ! dpkg-query -W -f='${Status}' apache 2>/dev/null | grep -q "ok installed"; then
    apt install -y apache
  fi
  systemctl enable apache
  systemctl start apache
elseif .....
  # ....
fi
```

You write:

```puppet
# Declarative (Puppet): WHAT you want
package { 'httpd':
  ensure => installed,
}

service { 'httpd':
  ensure => running,
  enable => true,
}
```

```console
puppet apply manifest.pp
```

Same result, but the Puppet version is idempotent, cross-platform (mostly), and self-documenting.
You might get excited and want to go writing a bunch of Puppet code now, but let's go another layer deeper.
What if you didn't even have to write any of this yourself?


### The Puppet Forge

One of the strengths of the OpenVox community is the vast amount of pre-written modules.
For example, let's say that you wanted to manage a simple nginx reverse proxy.
First, install the module:

```console
puppet module install puppet/nginx
```

Then declare the resources exposed by the `nginx` module:

```puppet
# set up nginx itself
include nginx

# then declare the resource you want to manage
nginx::resource::server { 'kibana.example.com':
  listen_port => 80,
  proxy       => 'http://localhost:5601',
}
```

```console
puppet apply nginx_reverse_proxy.pp
```

Many users won't need to learn more of the Puppet Language.
Instead, the [roles and profiles](/openvox/latest/the_roles_and_profiles_method.html) design pattern makes it easy to
build a composable and maintainable codebase with component modules sourced from the [Pupept Forge](https://forge.puppet.com).

If you do end up needing to write your own modules, then you can go further learning the language.
[Let's dive in](/openvox/latest/lang_visual_index.html).
