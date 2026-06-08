---
layout: default
title: "Running OpenVox Server from Source"
---

## So you'd like to run OpenVox Server from source?

The following steps will help you get OpenVox Server up and running from source.

## Quick Start for Developers

This quick start assumes the [prerequisites](#step-1-install-prerequisites) are already installed: Java and Leiningen to run the server, Git to check out the source, and Ruby 3.1 or later to run the
agent. See [Step 1](#step-1-install-prerequisites) for details.

```console
# clone git repository and initialize submodules
$ git clone --recursive https://github.com/OpenVoxProject/openvox-server
$ cd openvox-server

# Move any old config aside (rename rather than delete, so you can restore
# it) if you want to be sure you're starting from the latest defaults
$ mv ~/.puppetlabs ~/.puppetlabs.bak.$(date +%Y%m%d-%H%M%S)

# Run the `dev-setup` script to initialize all required configuration
$ ./dev-setup

# Launch the clojure REPL
$ lein repl
# Run Puppet Server
dev-tools=> (go)
dev-tools=> (help)
```

You should now have a running server. All relevant paths (`$confdir`, `$codedir`, etc.) are configured by default to point to directories underneath `~/.puppetlabs`. These should all align with the default
values that `puppet` uses (for non-root users).

You can find the specific paths in the `dev/puppetserver.conf` file.

In another shell, you can run the agent from source. Run it through Bundler so the source tree is isolated from any `puppet` or `openvox` gems installed in your Ruby (otherwise the two copies of
Puppet collide):

```console
# Go to the agent source in your openvox-server checkout
$ cd openvox-server/ruby/puppet
# Install the source tree's dependencies (first time only)
$ bundle install
# Run the source agent against your running server
$ bundle exec puppet agent -t --confdir ~/.puppetlabs/etc/puppet
```

More detailed instructions follow.

## Step 1: Install Prerequisites

Use your system's package tools to ensure that the following prerequisites are installed:

- Java 17 or 21
- [Leiningen 2.9.1 or later](http://leiningen.org/)
- Git (for checking out the source code)
- Ruby 3.1 or later -- only needed to run a Puppet Agent from source on the host (the source agent is run through Bundler, which isolates it from any Puppet gems in your Ruby). You can skip this if you
  [run the agent in a Docker container](#running-the-agent-inside-a-docker-container) instead.

## Step 2: Clone Git Repo and Set Up Working Tree

```console
git clone --recursive https://github.com/OpenVoxProject/openvox-server
cd openvox-server
```

## Step 3: Set up Config Files

The easiest way to do this is to just run:

```console
./dev-setup
```

This will set up all of the necessary configuration files and directories inside of your `~/.puppetlabs` directory. If you are interested in seeing what all of the default file paths are, you can find them in
`./dev/puppetserver.conf`.

The default paths should all align with the default values that are used by `puppet` (for non-root users).

If you'd like to customize your environment, here are a few things you can do:

- Before running `./dev-setup`, set an environment variable called `MASTERHOST`. If this variable is found during `dev-setup`, it will configure your `puppet.conf` file to use this value for your certname (both
  for Puppet Server and for `puppet`) and for the `server` configuration (so that your agent runs will automatically use this hostname as their Puppet Server).
- After running `./dev-setup`, you can enable autosigning so that agent certificate requests are signed automatically -- convenient when [running agents in Docker
  containers](#running-the-agent-inside-a-docker-container). Configure this before you start the server in Step 4 so the change is picked up without a restart. It is best suited to development
  environments rather than production:

  ```console
  puppet config set autosign true --section server
  ```

- Create a file called `dev/user.clj`. This file will be automatically loaded when you run Puppet Server from the REPL. In it, you can define a function called `get-config`, and use it to override the default
  values of various settings from `dev/puppetserver.conf`. For an example of what this file should look like, see `./dev/user.clj.sample`.

You don't need to create a `user.clj` in most cases; settings most likely to warrant it are:

- `jruby-puppet.max-active-instances`: the number of JRuby instances to put into the pool. This can usually be set to 1 for dev purposes, unless you're working on something that involves concurrency.
- `jruby-puppet.splay-instance-flush`: Do not attempt to splay JRuby flushing, set when testing if using multiple JRuby instances and you need to control when they are flushed from the pool
- `jruby-puppet.server-conf-dir`: the OpenVox Server confdir (where `puppet.conf`, `modules`, `manifests`, etc. should be located).
- `jruby-puppet.server-code-dir`: the OpenVox Server codedir
- `jruby-puppet.server-var-dir`: the OpenVox Server vardir
- `jruby-puppet.server-run-dir`: the OpenVox Server rundir
- `jruby-puppet.server-log-dir`: the OpenVox Server logdir

## Step 4a: Run the server from the clojure REPL

The preferred way of running the server for development purposes is to run it from inside the clojure REPL. The git repo includes some files in the `/dev` directory that are intended to make this process
easier.

When running a clojure REPL via the `lein repl` command-line command, lein will load the `dev/dev-tools.clj` namespace by default.

Running the server inside of the clojure REPL allows you to make changes to the source code and reload the server without having to restart the entire JVM. It can be much faster than running from the command
line, when you are doing iterative development. We are also starting to build up a library of utility functions that can be used to inspect and modify the state of the running server; see `dev/dev-tools.clj`
for more info.

(NOTE: many of the developers of this project are using a more full-featured IDE called [Cursive Clojure](https://cursiveclojure.com/), built on the IntelliJ IDEA platform, for our daily development. It
contains an integrated REPL that can be used in place of the `lein repl` command-line command, and works great with all of the functions described in this document.)

To start the server from the REPL, run the following:

```clojure
$ lein repl
nREPL server started on port 47631 on host 127.0.0.1
dev-tools=> (go)
dev-tools=> (help)
```

Then, if you make changes to the source code, all you need to do in order to restart the server with the latest changes is:

```clojure
dev-tools=> (reset)
```

Restarting the server this way should be significantly faster than restarting the entire JVM process.

You can also run the utility functions to inspect the state of the server, e.g.:

```clojure
dev-tools=> (print-puppet-environment-states)
```

Have a look at `dev-tools.clj` if you're interested in seeing what other utility functions are available.

## Step 4b: Run the server from the command line

If you prefer not to run the server interactively in the REPL, you can launch it as a normal process. To start the OpenVox Server when running from source, simply run the following:

```console
lein run -c /path/to/puppetserver.conf
```

## Step 4c: Development environment gotchas

### Missing git submodules

If you get an error like the following:

```text
Execution error (LoadError) at org.jruby.RubyKernel/require
(org/jruby/RubyKernel.java:970).
(LoadError) no such file to load -- puppet
```

Then you've probably forgotten to fetch the git submodules.

### Failing tests

If you change the `:webserver :ssl-port` config option from the default value of `8140`, tests will fail with errors like the following:

```text
lein test :only puppetlabs.general-puppet.general-puppet-int-test/test-external-command-execution

ERROR in (test-external-command-execution) (SocketChannelImpl.java:-2)
Uncaught exception, not in assertion.
expected: nil
2019-02-06 14:58:50,541 WARN  [async-dispatch-18] [o.e.j.s.h.ContextHandler] Empty contextPath
  actual: java.net.ConnectException: Connection refused
 at sun.nio.ch.SocketChannelImpl.checkConnect (SocketChannelImpl.java:-2)
    sun.nio.ch.SocketChannelImpl.finishConnect (SocketChannelImpl.java:717)
    org.apache.http.impl.nio.reactor.DefaultConnectingIOReactor.processEvent (DefaultConnectingIOReactor.java:171)
    org.apache.http.impl.nio.reactor.DefaultConnectingIOReactor.processEvents (DefaultConnectingIOReactor.java:145)
    org.apache.http.impl.nio.reactor.AbstractMultiworkerIOReactor.execute (AbstractMultiworkerIOReactor.java:348)
    org.apache.http.impl.nio.conn.PoolingNHttpClientConnectionManager.execute (PoolingNHttpClientConnectionManager.java:192)
    org.apache.http.impl.nio.client.CloseableHttpAsyncClientBase$1.run (CloseableHttpAsyncClientBase.java:64)
    java.lang.Thread.run (Thread.java:844)
```

Changing the `ssl-port` variable back to `8140` makes the tests run properly.

## Running the Agent

Use a command like the one below to run an agent against your running OpenVox Server:

```console
puppet agent --confdir ~/.puppetlabs/etc/puppet \
             --debug -t
```

Note that a system installed Puppet Agent is ok for use with source-based OpenVoxDB and OpenVox Server. The `--confdir` above specifies the same confdir that OpenVox Server is using. Because the Puppet Agent and
OpenVox Server instances are both using the same confdir, they're both using the same certificates as well. This alleviates the need to sign certificates as a separate step.

To run the agent from source instead -- for example, to exercise local changes to the agent code -- use the Bundler approach shown in [Quick Start for Developers](#quick-start-for-developers).

## Running the Agent inside a Docker container

You can run a Puppet Agent inside a Docker container to test against an OpenVox Server you are running from source. Unlike the host agent described above, a containerized agent has its own certificate
identity, so it must connect to the server by the **hostname** the server certificate was issued for. Connecting by the Docker host IP (for example `--server 172.17.0.1`) fails with a TLS hostname
mismatch, because the server certificate is issued for a name rather than an address.

### Prerequisites

Before starting the server (Step 4), configure it as described in [Step 3: Set up Config Files](#step-3-set-up-config-files):

- Run `MASTERHOST=puppet ./dev-setup` so the server certificate covers the `puppet` hostname the agent connects to.
- Enable autosigning so each new agent certificate is signed automatically, rather than signing each one by hand.

If you would rather sign certificates manually, see [Sign the agent certificate](#sign-the-agent-certificate) below.

### Start the agent

The agent image already defaults to the server name `puppet`, so you only need to make that name resolve to your Docker host. Map it with `--add-host`, and persist the agent's SSL directory in a
named volume so it keeps a stable key and certificate across runs:

```console
docker run -ti                                  \
       --name agent1                            \
       --add-host puppet:host-gateway           \
       -v agent1-ssl:/etc/puppetlabs/puppet/ssl \
       ghcr.io/openvoxproject/openvoxagent:8    \
       agent -t --certname agent1
```

- `--add-host puppet:host-gateway` resolves the `puppet` hostname inside the container to your Docker host, where the server you are running from source listens on port `8140`.
- `-v agent1-ssl:/etc/puppetlabs/puppet/ssl` persists the agent's keys and certificates in a named volume. Without it, each `docker run` generates a new private key, causing certificate/key
  mismatches on subsequent runs.

On Linux you can instead share the host's network stack with `--network host --add-host puppet:127.0.0.1`, which points the `puppet` hostname at the loopback address the server is bound to.

### Sign the agent certificate

With autosigning enabled in the [Prerequisites](#prerequisites), each agent certificate is signed automatically and you can skip this step.

If you turn autosigning off, the agent's first run submits a certificate signing request and then exits without compiling a catalog (`Certificate for agent1 has not been signed yet`). Sign the
pending request on the server, then run the agent again. From source, use the `puppetserver-ca` CLI and point it at your development config:

```console
puppetserver-ca sign --certname agent1 --config ~/.puppetlabs/etc/puppet/puppet.conf
```

The CLI signs by connecting to the running server under the name in that config (`puppet`), so that name must also resolve on the host running the command -- for example, with a `127.0.0.1 puppet`
entry in `/etc/hosts`. Because the SSL directory is persisted in the named volume, the agent reuses its signed certificate on every subsequent run.

### Re-running a container

To start a previously created agent container again, use the `docker start` command:

```console
docker start -a agent1
```

## Running tests

- `lein test` to run the clojure test suite
- `rake spec` to run the jruby test suite

The Clojure test suite can consume a lot of transient memory. Using a larger JVM heap size when running tests can significantly improve test run time. The default heap size is somewhat conservative: 1 GB for
the minimum heap (much lower than that as a maximum can lead to Java OutOfMemory errors during the test run) and 2 GB for the maximum heap. While the heap size can be configured via the `-Xms` and `-Xmx`
arguments for the `:jvm-opts` `defproject` key within the `project.clj` file, it can also be customized for an individual user environment via either of the following methods:

1. An environment variable named `PUPPETSERVER_HEAP_SIZE`. For example, to use a heap size of 6 GiB for a `lein test` run, you could run the following:

   ```console
   PUPPETSERVER_HEAP_SIZE=6G lein test
   ```

2. A lein `profiles.clj` setting in the `:user` profile under the `:puppetserver-heap-size` key. For example, to use a heap size of 6 GiB, you could add the following key to your `~/.lein/profiles.clj` file:

   ```clojure
   {:user {:puppetserver-heap-size "6G"
           ...}}
   ```

With the `:puppetserver-heap-size` key defined in the `profiles.clj` file, any subsequent `lein test` run would utilize the associated value for the key. If both the environment variable and the `profiles.clj`
key are defined, the value from the environment variable takes precedence. When either of these settings is defined, the value is used as both the minimum and maximum JVM heap size.

From anecdotal testing, at least a heap size of 5 GB provides the best performance benefit for full runs of the Clojure unit test suite. This value may change over time depending upon how the tests evolve.

## Installing Ruby Gems for Development

The gems that are vendored with the openvox-server OS packages will be automatically installed into your dev environment by the `./dev-setup` script. If you wish to install additional gems, please see the
[Gems](./gems.html) document for detailed information.

## Debugging

For more information about debugging both Clojure and JRuby code, please see [OpenVox Server: Debugging](./dev_debugging.html) documentation.

## Running OpenVoxDB

To run a source OpenVoxDB with OpenVox Server, OpenVox Server needs standard OpenVoxDB configuration and how to find the OpenVoxDB terminus. First copy the
`dev/puppetserver.conf` file to another directory. In your copy of the config, append a new entry to the `ruby-load-path` list: `<PDB source path>/puppet/lib`. This tells
OpenVox Server to load the OpenVoxDB terminus from the specified directory.

From here, the instructions are similar to installing OpenVoxDB manually via packages. The OpenVox Server instance needs configuration for connecting to OpenVoxDB. See the
[OpenVoxDB documentation](/openvoxdb/latest/connect_puppet_server.html) for details.

Update `~/.puppetlabs/etc/puppet/puppet.conf` to include:

```ini
[server]
storeconfigs = true
storeconfigs_backend = puppetdb
reports = store,puppetdb
```

Create a new puppetdb config file `~/.puppetlabs/etc/puppet/puppetdb.conf` that contains

```ini
[main]
server_urls = https://<MASTERHOST>:8081
```

Then create a new routes file at `~/.puppetlabs/etc/puppet/routes.yaml` that contains

```yaml
---
server:
  facts:
    terminus: puppetdb
    cache: yaml
```

Assuming you have an OpenVoxDB instance up and running, start your OpenVox Server instance with the new puppetserver.conf file that you changed:

```console
lein run -c ~/<YOUR CONFIG DIR>/puppetserver.conf
```

Depending on your OpenVoxDB configuration, you might need to change some SSL config. OpenVoxDB requires that the same CA that signs its certificate also has signed OpenVox Server's certificate. The easiest way
to do this is to point OpenVoxDB at the same configuration directory that OpenVox Server and Puppet Agent are pointing to. Typically this setting is specified in the `jetty.ini` file in the OpenVoxDB conf.d
directory. The update would look like:

```ini
[jetty]

#...
ssl-cert = <home dir>/.puppetlabs/etc/puppet/ssl/certs/<MASTERHOST>.pem
ssl-key = <home dir>/.puppetlabs/etc/puppet/ssl/private_keys/<MASTERHOST>.pem
ssl-ca-cert = <home dir>/.puppetlabs/etc/puppet/ssl/certs/ca.pem
```

After the SSL config is in place, start (or restart) OpenVoxDB:

```console
lein run services -c <path to PDB config>/conf.d
```

Then run the Puppet Agent and you should see activity in OpenVoxDB and OpenVox Server.
