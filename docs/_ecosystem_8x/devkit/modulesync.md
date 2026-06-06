---
layout: default
title: "Manage an Entire Portfolio of Modules with ModuleSync"
---

Puppet modules within an organization tend to have a number of boilerplate files that are identical or very similar between modules, such as the `Gemfile`, `LICENSE.md`,
CI configuration, or `.spec_helper.rb` configuration for the testing framework.
If a file needs to change in one module, it likely needs to change in the same way in every other module that the organization manages.
This is even true when the files are not exactly the same.
For example, organizations with robust CI testing will often pre-flight OS upgrades by bumping the supported OS version in module `metadata.json` files and then letting CI tell them what needs to be fixed.

This is a very convenient way to work, but hard to do consistently when dealing with more than a handful of modules.
ModuleSync lets you make these tweaks across multiple modules at once, scaling it to an entire portfolio.

## Getting Started

ModuleSync works by running within a configuration directory and template directory.
The `moduleroot` subdirectory mirrors a module directory tree and contains an `.erb` template for each file that should be managed -- even the static files like the license or `.gitignore`.
On each _sync_ run, each template is rendered using configuration variables for each managed module.
These changes can then be _pushed_ to each module repository or _submitted as a pull/merge request_.

Start by forking & cloning [Vox Pupuli's modulesync_config](https://github.com/voxpupuli/modulesync_config) or creating your own using it as an example.
Poke through the `moduleroot` and remove the files you don't need, add the files you do need, and update the templates to match your own requirements.
In particular, you might want to simplify if you're not planning to use the GitHub actions or the CI based maintenance workflow.

### Configuring the templates

Next, you'll want to configure the templates by editing `config_defaults.yml`.
Each key in this file is the filename of a managed file and can have any number of variables specified underneath.
One interesting special key is `delete: true` nested underneath a filename.
This will remove the file if it exists and is useful for migrating away from tools you're no longer using.

You can also use the reserved key of `global` to provide variables that each template can access.

For example, this configuration instructs ModuleSync to render `.puppet-lint.rc` with two disabled checks.

```yaml
.puppet-lint.rc:
  disabled_lint_checks:
    - parameter_documentation
    - parameter_types
```

The template for this could look like the following simplified version of Vox Pupuli's template.

```erb
<% @configs['disabled_lint_checks'].each do |check| -%>
--no-<%= check %>-check
<% end -%>
```

Each module can override these variables for itself by adding a `sync.yml` file in its own directory root.

### Configuring ModuleSync

Edit `modulesync.yml` with your own git information.
Ensure that the `namespace` is set to your own git provider's username and set the `git_base` appropriately.
For example, a GitHub user might configure like so:

```yaml
---
git_base: 'git@github.com:'
namespace: your_username
branch: modulesync
message: "Update from modulesync_config"
```

### Selecting Modules

The `managed_modules.yml` file contains a list of all the modules you want to manage.
They should all be in the namespace configured in `modulesync.yml`.

For example, the modules described in this configuration would be found at `https://github.com/your_username/puppet-amanda` and so forth.

```yaml
---
- puppet-amanda
- puppet-aptly
- puppet-archive
- puppet-bacula
```

## Initial Module Sync and Update

Now that the config repo is set up, you'll clone your modules locally so that they can be updated.
If your module repositories are private, you'll need to authenticate first.
You can do this by exporting either `GITHUB_TOKEN` or `GITLAB_TOKEN` or by providing git with an SSH key or configuring an HTTP helper.

```console
bundle install

bundle exec msync update --noop
```

This should clone all your modules into `modules/$namespace` and render any updates locally.
If it fails, then correct any errors and run it again.

Because we ran with `--noop`, it won't attempt to commit or push changes.
Inspect each module to validate that it's in the state you expected.
You can use `git diff` to easily see what changed.
Fix templates or configuration settings and re-run the `--noop` update until you're happy with the outcome.

When you're ready to push updates, you can do so with:

```console
bundle exec msync update -m "Commit message"
```

If you'd rather submit pull/merge requests for review, then pass the `--pr` flag, which will require either `GITHUB_TOKEN` or `GITLAB_TOKEN` to be set.

```console
export GITHUB_TOKEN=<token>

bundle exec msync update --pr"
```

## Scripting Updates

Not all files or updates can be templated.
For example, if you needed to bump the supported range of the `stdlib` module across your whole portfolio, that would involve editing each module's `metadata.json` separately because they all have different information.

ModuleSync doesn't directly do this for you, but it will facilitate syncing updates that you script out yourself.
If you cloned [Vox Pupuli's modulesync_config](https://github.com/voxpupuli/modulesync_config) you'll find a bunch of helper scripts in the `bin` directory and a couple handy Rake tasks defined.

For example, you can get a list of outdated module dependencies with:

```console
bundle exec rake metadata_deps
```

And if you'd like to bump a dependency's supported version upper bound, it might look like so:

```console
./bin/bump-dependency-upper-bound puppetlabs/stdlib 10.0.0 modules/*/*/metadata.json
```

Verify it by running `metadata_deps` again and then when you're ready to commit and optionally push changes, you can do so with a little bit of CLI scripting:

```console
for module in modules/*/* ; do
  (
    cd $module
    if git diff --exit-code metadata.json ; then
      git commit -m 'Mark compatible with puppetlabs/stdlib 9.x' metadata.json
      # gh pr create --fill # uncomment to submit a pull request
    fi
  )
done
```

## More Information

Both ModuleSync and Vox Pupuli's configuration are far more powerful and feature complete than this guide has space for.
Read through each of their documentation to see what more you can do with it.

* [ModuleSync](https://github.com/voxpupuli/modulesync)
* [Vox Pupuli's modulesync_config](https://github.com/voxpupuli/modulesync_config)
