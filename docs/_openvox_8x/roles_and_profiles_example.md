---
layout: default
title: "Roles and profiles example"
---

This example demonstrates a complete roles and profiles workflow. Use it to understand the roles and profiles method as a whole. Additional examples show how
to design advanced configurations by refactoring this example code to a higher level of complexity.

## Configure Jenkins master servers with roles and profiles

Jenkins is a continuous integration (CI) application that runs on the JVM. The Jenkins master server provides a web front-end, and also runs CI tasks at scheduled times or in reaction to events.

In this example, we manage the configuration of Jenkins master servers.

### Set up your prerequisites

If you're new to using roles and profiles, do some additional setup before writing any new code.

1. Create two modules: one named `role`, and one named `profile`.

   Keep them in your control repository rather than declaring them in your Puppetfile, because r10k manages the `modules` directory itself and removes anything there that it did not deploy. The usual layout, and the one the [OpenVox control repository template](https://github.com/OpenVoxProject/control-repo-template) ships, is:

   1. Make a new directory in the repository named `site-modules`.
   2. Edit the `environment.conf` file to add `site-modules` to the `modulepath`, ahead of `modules`. (For example: `modulepath = site-modules:modules:$basemodulepath`).
   3. Put the `role` and `profile` modules in the `site-modules` directory.

   This layout is where to start. As the number of profiles and the number of teams writing them grow, you can move profiles into ordinary modules that you version and deploy through the Puppetfile like any other module.
   A profile module can carry its own parameter defaults in [the module layer of Hiera](hiera_intro.html#the-module-layer), so it needs nothing from the control repository beyond a Puppetfile entry. Roles stay in the control repository: they are short, and they change with your fleet rather than with any one technology.

2. Make sure [Hiera](./hiera_intro.html) or Puppet lookup is set up and working, with a hierarchy that works well for you.

### Choose component modules

For our example, we want to manage Jenkins itself. The standard module for that is `rtyler/jenkins`.

Jenkins requires Java, and the `rtyler` module can manage it automatically. But we want finer control over Java, so we're going to disable that. So, we need a
Java module, and `puppetlabs/java` is a good choice.

That's enough to start with. We can refactor and expand when we have those working.

To learn more about these modules, see [rtyler/jenkins](https://forge.puppet.com/rtyler/jenkins) and [puppetlabs/java](https://forge.puppet.com/puppetlabs/java).

### Write a profile

From a Puppet perspective, a profile is just a normal class stored in the `profile` module.

Make a new class called `profile::jenkins::master`, located at `.../profile/manifests/jenkins/master.pp`, and fill it with Puppet code:

```puppet
# /etc/puppetlabs/code/environments/production/site-modules/profile/manifests/jenkins/master.pp
class profile::jenkins::master (
  Integer $jenkins_port = 9091,
  String $java_dist    = 'jdk',
  String $java_version = 'latest',
) {

  class { 'jenkins':
    configure_firewall => true,
    install_java       => false,
    port               => $jenkins_port,
    config_hash        => {
      'HTTP_PORT'    => { 'value' => $jenkins_port },
      'JENKINS_PORT' => { 'value' => $jenkins_port },
    },
  }

  class { 'java':
    distribution => $java_dist,
    version      => $java_version,
    before       => Class['jenkins'],
  }
}
```

This is pretty simple, but is already benefiting us: our interface for configuring Jenkins has gone from 30 or so parameters on the Jenkins class (and many more
on the Java class) down to three. Notice that we've hardcoded the `configure_firewall` and `install_java` parameters, and have reused the value of
`$jenkins_port` in three places.

### Set data for the profile

Let's assume the following:

- Each node's certificate carries one more [extension request](ssl_attributes_extensions.html#extension-requests-permanent-certificate-data) besides `pp_role`, set in `csr_attributes.yaml` before its first run (see [Assign the role to nodes](#assign-the-role-to-nodes)):
  - `pp_application`: The application or team the node serves. Most of our Jenkins masters serve `ci`.

  A fact could carry the same information, but a node reports its own facts and anyone with root access to it can change them. Certificate extensions are signed by the CA, and the node cannot change them.

- Each node has a custom fact, `stage`, that gives its deployment stage: `dev`, `test`, or `prod`. The stage only selects data such as port numbers, so a fact is fine for it.

- We have a four-layer hierarchy:
  - `nodes/%{trusted.certname}` for per-node overrides.
  - `applications/%{trusted.extensions.pp_application}/%{facts.stage}` for stage-specific data within an application.
  - `applications/%{trusted.extensions.pp_application}` for application-specific data.
  - `common` for global fallback data.

- We have a few one-off Jenkins masters, but most of them serve the `ci` application.
- Our quality engineering department wants the `ci` masters to use the Oracle JDK, but one-off machines can just use the platform's default Java.
- QE also wants their prod masters to listen on port 80.

Set appropriate values in the Hiera data:

```yaml
# /etc/puppetlabs/code/environments/production/data/nodes/ci-master01.example.com.yaml
# --Nothing. We don't need any per-node values right now.

# /etc/puppetlabs/code/environments/production/data/applications/ci/prod.yaml
profile::jenkins::master::jenkins_port: 80

# /etc/puppetlabs/code/environments/production/data/applications/ci.yaml
profile::jenkins::master::java_dist: 'oracle-jdk8'
profile::jenkins::master::java_version: '8u92'

# /etc/puppetlabs/code/environments/production/data/common.yaml
# --Nothing. Just use the default parameter values.
```

### Write a role

To write roles, we consider the machines we'll be managing and decide what else they need in addition to that Jenkins profile.

Our Jenkins masters don't serve any other purpose. But we have some profiles (code not shown) that we expect every machine in our fleet to have:

- `profile::base` must be assigned to every machine, including workstations. It manages basic policies, and uses some conditional logic to include OS-specific profiles as needed.
- `profile::server` must be assigned to every machine that provides a service over the network. It makes sure ops can log into the machine, and configures
  things like timekeeping, firewalls, logging, and monitoring.

So a role to manage one of our Jenkins masters should include those classes as well.

```puppet
class role::jenkins::master {
  include profile::base
  include profile::server
  include profile::jenkins::master
}
```

### Assign the role to nodes

Finally, we assign `role::jenkins::master` to every node that acts as a Jenkins master.

OpenVox does not ship a node classifier. You assign roles with Hiera, with an external node classifier (ENC) that you provide, or in the main manifest. Hiera is the usual choice: the assignment lives in the same repository as the roles, and it goes through the same review and deployment process as the rest of your code.

#### Hiera

Give each node a piece of trusted data that names its role, add a hierarchy level that selects on that data, and have the main manifest include whatever the `classes` key resolves to.

1. Set the role on the node before its first run, as an [extension request](ssl_attributes_extensions.html#extension-requests-permanent-certificate-data) in [`csr_attributes.yaml`](config_file_csr_attributes.html). The registered `pp_role` OID exists for this purpose:

   ```yaml
   # /etc/puppetlabs/puppet/csr_attributes.yaml on the node
   ---
   extension_requests:
     pp_role: jenkins_master
     pp_application: ci
   ```

   The CA copies the extensions into the signed certificate, where manifests and Hiera can read them as `trusted.extensions.pp_role` and so on. The node cannot change them afterwards, which is what makes them safe to drive classification from. The `pp_application` value is the one [Set data for the profile](#set-data-for-the-profile) relies on.

   If your provisioning process cannot write `csr_attributes.yaml`, a custom fact works the same way in the hierarchy, without the trust described above.

2. Add a level to the hierarchy that is keyed on the role. Extending the hierarchy from [Set data for the profile](#set-data-for-the-profile):

   ```yaml
   # /etc/puppetlabs/code/environments/production/hiera.yaml
   ---
   version: 5
   defaults:
     datadir: data
     data_hash: yaml_data
   hierarchy:
     - name: "Per-node data"
       path: "nodes/%{trusted.certname}.yaml"
     - name: "Per-role data"
       path: "roles/%{trusted.extensions.pp_role}.yaml"
     - name: "Per-application, per-stage data"
       path: "applications/%{trusted.extensions.pp_application}/%{facts.stage}.yaml"
     - name: "Per-application data"
       path: "applications/%{trusted.extensions.pp_application}.yaml"
     - name: "Common data"
       path: "common.yaml"
   ```

3. Name the role class in that level's data file:

   ```yaml
   # /etc/puppetlabs/code/environments/production/data/roles/jenkins_master.yaml
   classes:
     - role::jenkins::master
   ```

4. In the main manifest, look up `classes` with a unique merge and include the result:

   ```puppet
   # /etc/puppetlabs/code/environments/production/manifests/site.pp
   lookup('classes', Array[String], 'unique', []).include
   ```

   The fourth argument is the default, used only when no level of the hierarchy defines `classes`. Leave it empty to give unclassified nodes an empty catalog, or set it to a baseline such as `['role::base']`.

Keep one role class in each role data file, and leave `classes` out of `common.yaml` and the application levels. The unique merge collects the key from every level, so listing classes at a shared level gives every node more than one role.

For variants of this pattern, including a hash form that lets a more specific level replace or disable a class, see [Modern Puppet node classification](https://dev.to/betadots/modern-puppet-node-classification-3ngk).

#### An external node classifier

An [ENC](nodes_external.html) is a script or service that the server calls with the node's certname, and that returns the classes and environment for that node. Foreman is the best-known ENC with a user interface. A short script that looks the node up in an inventory system or a provisioning database is the other common form.

Use an ENC when the assignment has to come from outside the control repository. Have it return only the role class, and keep profile parameters in Hiera, so that the data stays in one place and the role class still decides what the node runs.

#### The main manifest

[Node definitions](lang_node_definitions.html) in `site.pp` can assign a role directly, by certname or by regular expression. A naming convention that encodes the role in the hostname keeps this to a short list:

```puppet
# /etc/puppetlabs/code/environments/production/manifests/site.pp
node /^ci-master\d+\.example\.com$/ {
  include role::jenkins::master
}
```

This is the quickest way to get started, and many long-running deployments began this way. It does not scale well: every new node type is another regular expression in one shared file, and anything the hostname does not encode has nowhere to go. Plan to move the assignment into Hiera once the list grows.
