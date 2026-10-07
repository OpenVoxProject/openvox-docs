---
layout: default
title: "Deploying Code with r10k"
---

You have a server, an agent, and a control repository on your git server.
What's missing is the step that gets your control repository onto the OpenVox server, and keeps it there as you push changes.
That job belongs to [r10k](https://github.com/voxpupuli/r10k): it reads the `Puppetfile` in your control repository, installs the modules it lists, and turns every branch into an environment on the server.

**What you'll learn:**

* [Installing r10k and pointing it at your control repository](#install-r10k)
* [Giving r10k read access with a deploy key](#give-r10k-access-to-your-repository)
* [Running your first deploy](#deploy-by-hand)
* [Deploying automatically with a timer or a webhook](#deploy-automatically)
* [Configuring GitHub or GitLab to call the webhook](#configure-your-git-server)

## Prerequisites

Before you start, you'll need:

* The OpenVox server you built on the [previous page](agent-server.html), with root or `sudo` access
* A control repository pushed to a git server, with a `production` branch. The [OpenVox control repository template](https://github.com/OpenVoxProject/control-repo-template) is the quickest way to get one.
* Network access from the OpenVox server to the git server over SSH, and for the webhook, from the git server back to the OpenVox server

All commands on this page run on the OpenVox server node.

The `puppet-r10k` release used here declares support for OpenVox 8 only.
On an OpenVox 9 server, check the [module's dependencies](https://forge.puppet.com/modules/puppet/r10k/dependencies) for a release that lists OpenVox 9 before relying on it.
{: .tip }

## Install r10k

The [`puppet/r10k`](https://forge.puppet.com/modules/puppet/r10k) module installs r10k into the Ruby that ships with the OpenVox agent and writes its configuration file.
Later, the same module can manage r10k from your control repository, but for the first run you'll apply it by hand.

Install the module and its dependencies into a scratch directory so they don't end up in your `production` environment:

```console
sudo puppet module install puppet-r10k --modulepath /tmp/r10k-bootstrap
```

Then apply the `r10k` class, with `remote` set to the SSH clone URL of your control repository:

```console
sudo puppet apply --modulepath /tmp/r10k-bootstrap \
  -e "class { 'r10k': remote => 'git@gitlab.example.com:puppet/control-repo.git' }"
```

This installs the `r10k` gem as `/opt/puppetlabs/puppet/bin/r10k`, links it from `/usr/bin/r10k` so it's on your `PATH`, and writes `/etc/puppetlabs/r10k/r10k.yaml`:

```yaml
---
pool_size: 4
deploy:
  generate_types: true
  exclude_spec: true
cachedir: "/opt/puppetlabs/puppet/cache/r10k"
sources:
  puppet:
    basedir: "/etc/puppetlabs/code/environments"
    remote: git@gitlab.example.com:puppet/control-repo.git
```

The `basedir` is the server's `environmentpath`, so every branch of the control repository becomes a directory under it.
The `production` branch becomes the `production` environment that your agents already use.

Name your branches the way you'd name an environment: lowercase letters, digits, and underscores.
r10k replaces other characters with underscores and warns about it on every run, so a branch called `feature-x` becomes an environment called `feature_x`.
The deploy still works, including from a webhook, but the warning never goes away and the environment name no longer matches the branch.
{: .tip }

## Give r10k access to your repository

r10k shells out to `git`, so it uses whatever SSH configuration the user running it has.
The webhook service and cron both run r10k as `root`, so create a key for `root` and register its public half as a read-only deploy key on the control repository.

```console
sudo ssh-keygen -t ed25519 -N '' -C "r10k@$(hostname -f)" \
  -f /root/.ssh/id_ed25519
sudo cat /root/.ssh/id_ed25519.pub
```

Add the public key to the repository:

* **GitHub:** repository **Settings > Deploy keys > Add deploy key**. Leave **Allow write access** unchecked.
* **GitLab:** project **Settings > Repository > Deploy keys > Add new key**. Leave **Grant write permissions to this key** unchecked.

Then add the git server's host key so the first clone doesn't stop at an interactive prompt, and confirm that the key works:

```console
sudo sh -c 'ssh-keyscan gitlab.example.com >> /root/.ssh/known_hosts'
sudo ssh -T git@gitlab.example.com
```

GitHub answers with a line that names the repository the key is attached to, and GitLab with `Welcome to GitLab`.

If you track modules from git in your `Puppetfile`, the same key needs read access to those repositories too.
On GitHub, a deploy key is tied to one repository; use a [machine user](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys#machine-users) if r10k needs to read several.
{: .tip }

## Deploy by hand

Run a full deploy once, so you can see it work before you automate it:

```console
sudo /opt/puppetlabs/puppet/bin/r10k deploy environment --modules --verbose
```

r10k clones the control repository, creates one directory per branch under `/etc/puppetlabs/code/environments/`, and installs every module from the `Puppetfile` into each one.
The first run takes a while if your `Puppetfile` is long; later runs only fetch what changed.

Check the result:

```console
ls /etc/puppetlabs/code/environments/
ls /etc/puppetlabs/code/environments/production/modules/
```

Then run the agent on one of your nodes to confirm that it compiles against the deployed code:

```console
sudo puppet agent -t
```

r10k owns everything under `basedir`.
A deploy removes any environment directory that doesn't match a branch, including code you placed there by hand.
If you edited `site.pp` directly on the server while following the previous page, move that change into the control repository before your first deploy.
{: .tip }

### Let the control repository manage r10k

Now that the server deploys from your control repository, let the control repository manage r10k from here on.
Add the module and its dependencies to your `Puppetfile`:

```ruby
mod 'puppet/r10k',          '15.2.0'
mod 'puppet/systemd',       '9.4.0'
mod 'puppetlabs/stdlib',    '9.7.0'
mod 'puppetlabs/inifile',   '6.5.0'
mod 'puppetlabs/vcsrepo',   '7.0.0'
mod 'choria/mcollective',   '0.15.0'
```

The module's dependency ranges change between releases, so check the [dependencies tab](https://forge.puppet.com/modules/puppet/r10k/dependencies) on the Forge for the version you install.

Then classify the server with the `r10k` class, for example from `manifests/site.pp`:

```puppet
node 'openvox.example.com' {
  class { 'r10k':
    remote => 'git@gitlab.example.com:puppet/control-repo.git',
  }
}
```

Push, deploy once more by hand, and run the agent on the server.
From now on, the configuration in `r10k.yaml` comes from your control repository like everything else.
You can delete `/tmp/r10k-bootstrap`.

## Deploy automatically

You have two common choices for triggering deploys: run r10k on a schedule, or run it when the git server reports a push.
Scheduled deploys are simpler and need no inbound connection to the OpenVox server.
Push-triggered deploys are immediate, which matters as soon as you have more than one person waiting on their changes.

### On a schedule

A cron entry that deploys every fifteen minutes is enough for many sites:

```text
*/15 * * * * root /opt/puppetlabs/puppet/bin/r10k deploy environment --modules
```

Save it as `/etc/cron.d/r10k`, or manage it with a `cron` resource from your control repository.

### On push, with webhook-go

[webhook-go](https://github.com/voxpupuli/webhook-go) is a small service from Vox Pupuli that listens for push notifications from your git server and runs r10k for the branch that changed.
It understands the webhook payloads sent by GitHub, GitLab, Gitea, Bitbucket Cloud, Bitbucket Server, and Azure DevOps, and tells them apart by their request headers.

The `r10k::webhook` class installs it from the package on the webhook-go releases page, writes `/etc/voxpupuli/webhook.yml`, and runs it as a systemd service named `webhook-go`.
Add the class next to `r10k` in your control repository:

```puppet
node 'openvox.example.com' {
  class { 'r10k':
    remote => 'git@gitlab.example.com:puppet/control-repo.git',
  }

  class { 'r10k::webhook':
    server => {
      protected => true,
      user      => 'deploy',
      password  => 'change-me',
      port      => 4000,
      queue     => {
        enabled => true,
      },
    },
  }
}
```

Keep the password out of the manifest in real use: put it in Hiera and look it up, or use [`Sensitive`](/openvox/latest/lang_data_sensitive.html).

A few points about this configuration:

* **Authentication is HTTP basic auth only.** webhook-go does not check the secret token or signature that GitHub and GitLab can attach to a webhook, so `protected` plus a strong password is the only thing standing between the internet and an r10k run. Keep `protected` set to `true`.
* **Enable the queue.** GitHub and GitLab give up on a webhook delivery after about ten seconds. With the queue enabled, webhook-go answers immediately and runs r10k in the background, so a long module install doesn't show up as a failed delivery on the git server.
* **Use TLS when the git server is outside your network.** Set `tls => { enabled => true, certificate => '/path/to/cert.pem', key => '/path/to/key.pem' }`. The server's own OpenVox certificate works, but GitHub and GitLab won't trust the OpenVox CA, so either put a certificate from a public CA here or turn off SSL verification on the hook.
* **Open the port.** The git server must be able to reach port `4000` on the OpenVox server.

After the agent runs, check that the service is listening:

```console
sudo systemctl status webhook-go
curl -s http://localhost:4000/health
```

You can also trigger a deploy of `production` from the server itself, by sending a request shaped like a GitLab push event.
The header is what tells webhook-go which format to parse:

```console
curl -u deploy:change-me \
  -H 'Content-Type: application/json' \
  -H 'X-Gitlab-Event: Push Hook' \
  -d '{"ref": "refs/heads/production",
       "after": "1111111111111111111111111111111111111111",
       "project": {"name": "control-repo",
                   "path_with_namespace": "puppet/control-repo"}}' \
  http://localhost:4000/api/v1/r10k/environment
```

webhook-go answers `202 Accepted` and runs `r10k deploy environment production --modules --generate-types --verbose`.
Watch it with `sudo journalctl -u webhook-go -f`.

webhook-go lowercases the branch name before handing it to r10k, and passes it through otherwise unchanged.
If your branches use uppercase letters on purpose, set `allow_uppercase` to `true` in the `r10k` section of the class.
{: .tip }

## Configure your git server

The webhook URL for environment deploys is:

```text
https://deploy:change-me@openvox.example.com:4000/api/v1/r10k/environment
```

Put the basic-auth user and password in the URL itself; both GitHub and GitLab send them as an `Authorization` header.
Use `http://` instead of `https://` if you didn't enable TLS.

### GitHub

1. Open the control repository's **Settings > Webhooks** and select **Add webhook**.
2. Set **Payload URL** to the URL above and **Content type** to `application/json`.
3. Leave **Secret** empty. webhook-go ignores it.
4. Under **Which events would you like to trigger this webhook?**, keep **Just the push event**.
5. Select **Add webhook**.

GitHub sends a `ping` event straight away, which webhook-go rejects with a `500`, because it isn't a push.
That is expected.
Push a commit to confirm that real deliveries work, and use the **Recent Deliveries** tab on the webhook to see webhook-go's reply to each one.

### GitLab

1. Open the project's **Settings > Webhooks** and select **Add new webhook**.
2. Set **URL** to the URL above. Leave **Secret token** and **Signing token** empty; webhook-go checks neither.
3. Under **Trigger**, select **Push events**.
4. Keep **Enable SSL verification** on unless you are using the OpenVox CA's certificate.
5. Select **Add webhook**, then use **Test > Push events** on the new hook to send a sample push.

On a self-managed GitLab, adding the hook can fail with `Invalid url given` (or `Url is blocked: Requests to the local network are not allowed` in the UI) when the OpenVox server has a private address, which it usually does.
GitLab refuses to call webhooks on the local network by default.
An administrator can allow it under **Admin > Settings > Network > Outbound requests**, either by enabling **Allow requests to the local network from webhooks and integrations** or by adding `openvox.example.com:4000` to the allowlist below it.
The hostname must also resolve from the GitLab host, because GitLab looks it up before accepting the hook.
GitLab caches this setting for about a minute, so a push right after the change can still fail with `internal error` in the hook's delivery log; wait a minute and resend it from the same log.
{: .tip }

### Other git servers

Gitea uses the same **Settings > Webhooks > Add webhook > Gitea** flow as GitHub, with the same URL.
For Bitbucket and Azure DevOps, see the [webhook-go README](https://github.com/voxpupuli/webhook-go#readme).

### Module repositories

If your `Puppetfile` tracks a module by branch rather than by tag, pushing to the module repository doesn't change the control repository, so the hook above never fires.
Add a second webhook on the module repository, pointed at the module endpoint:

```text
https://deploy:change-me@openvox.example.com:4000/api/v1/r10k/module
```

webhook-go runs `r10k deploy module <name>` for it, taking the module name from the repository name.
Add `?module_name=<name>` to the URL when the two differ.

### Creating hooks from Puppet

The `puppet-r10k` README shows a `git_webhook` resource that creates the hook through the git server's API.
That type comes from the `abrader-gms` module, which is no longer maintained; the examples point at a personal fork's `fixup` branch to keep it working with current GitHub and GitLab APIs.
Creating the hook once by hand, as above, is simpler and doesn't depend on an unmaintained module.

If you use it anyway, the token it authenticates with needs the right to manage hooks, not just to read code.
On GitLab, that is a personal or project access token with the `api` scope, and the account or token role behind it must be at least Maintainer on the project; `read_api`, `read_repository`, and `write_repository` cannot create hooks.
The same role is what `git_deploy_key` needs.
On GitHub, a classic token needs the `write:repo_hook` scope (or `repo`), and a fine-grained token needs **Webhooks: write** on the repository.

## Troubleshooting

* **The git server shows a failed delivery with status `401`.** The user and password in the hook URL don't match `server.user` and `server.password` in `/etc/voxpupuli/webhook.yml`.
* **Status `500` with `Error Parsing Webhook`.** The request didn't carry a header webhook-go recognizes, or wasn't a push event. GitHub's initial `ping` does this; so does a plain `curl` without an `X-Gitlab-Event` or `X-Github-Event` header.
* **Status `500` with r10k output in the body.** r10k itself failed. Run the same `r10k deploy environment` command by hand as `root` to see the full error, which is usually a missing deploy key or an unresolvable module.
* **The delivery timed out.** Enable the queue in `r10k::webhook` so the service answers before r10k finishes. With the queue on, `GET /api/v1/queue` (with the same basic auth) lists recent jobs and their r10k output.
* **The push deployed, but agents still get old code.** By default the server reads environments fresh on every request. If you set [`environment_timeout`](/openvox/latest/configuration.html#environment_timeout) to `unlimited` for performance, the server keeps serving the cached code until something flushes it.
  r10k's `postrun` setting can call the [environment cache endpoint](/openvox-server/latest/admin-api/v1/environment-cache.html) after each deploy.

## Next Steps

* Dive a little deeper into how the whole [OpenVox infrastructure is architected](architecture.html).
* See how to [orchestrate](orchestration.html) one-off tasks.
