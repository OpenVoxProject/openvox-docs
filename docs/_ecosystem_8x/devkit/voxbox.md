---
layout: default
title: "Using VoxBox in CI"
---

[VoxBox](https://github.com/voxpupuli/container-voxbox) is a container image that bundles the Vox Pupuli developer toolkit.
It lets you run the testing and linting tasks without installing Ruby, Bundler, or the gems yourself.
All you need is a container runtime like Docker or Podman.

This makes it especially handy in CI pipelines, where you want a clean, reproducible environment for every run.

## When to use VoxBox

Use VoxBox when you want the devkit tooling without managing a local Ruby toolchain, particularly in CI.

If you're working locally and already have a Ruby environment, the [`voxpupuli-test` suite](setup.html#setting-up-the-vox-pupuli-test-suite) installed via your `Gemfile` is usually the more convenient choice.
VoxBox shines when you want isolation from the host, identical behavior across machines, or a turnkey CI image.

As of June 2026, GitHub Actions users generally don't need VoxBox: Vox Pupuli modules run the
shared reusable workflows ([`voxpupuli/gha-puppet`](https://github.com/voxpupuli/gha-puppet)),
which don't use VoxBox yet (see [gha-puppet#96](https://github.com/voxpupuli/gha-puppet/pull/96)).
VoxBox is most useful for GitLab CI and local runs.

## Running tasks locally

Mount your module directory into the container at `/repo` and pass a rake task name.
The image entrypoint is `bundle exec rake -f /opt/voxbox/Rakefile`, so anything you pass after the image name is treated as a rake task.

```console
cd puppet-example
podman run -it --rm -v "$PWD:/repo:Z" ghcr.io/voxpupuli/voxbox:latest spec
```

With Docker, drop the `:Z` SELinux relabel flag if your system doesn't use it:

```console
docker run -it --rm -v "$PWD:/repo" ghcr.io/voxpupuli/voxbox:latest lint
```

Run the container with no task to list everything available (the entrypoint runs `rake -T` for you):

```console
podman run -it --rm -v "$PWD:/repo:Z" ghcr.io/voxpupuli/voxbox:latest
```

Common tasks include `spec`, `lint`, `validate`, `rubocop`, and the same `voxpupuli-test` tasks described elsewhere in this guide.

If you run VoxBox locally a lot, the bundled [EasyVoxBox (`evb`)](https://github.com/voxpupuli/container-voxbox#easyvoxbox-evb)
helper script shortens these commands and lets you pass options in any order, which is handy for shell aliases.
Use `evb --noop <task>` to print the full command it would run without executing it.

## GitLab CI

Running VoxBox under GitLab CI requires one non-obvious change: you **must blank the image entrypoint** with `entrypoint: [""]`.
The [container-voxbox GitLab docs](https://github.com/voxpupuli/container-voxbox#gitlab) cover the same setup upstream.

GitLab runners start your job by launching a shell and feeding it your `script:`.
If the image keeps its default entrypoint (`bundle exec rake -f /opt/voxbox/Rakefile`), GitLab hands that shell invocation to rake as a task name instead of running your script, and the job fails before it starts.
Blanking the entrypoint lets the runner open a shell, after which you call rake yourself.

```yaml
stages:
  - lint

variables:
  # Mirrors the container entrypoint so jobs read cleanly.
  RAKE: bundle exec rake -f /opt/voxbox/Rakefile

default:
  image:
    name: ghcr.io/voxpupuli/voxbox:latest
    entrypoint: [""]

lint:puppet:
  stage: lint
  script:
    - $RAKE voxpupuli:custom:lint_all
```

Note the Rakefile path: on current images the bundled Rakefile lives at `/opt/voxbox/Rakefile`.
On older images it lived at `/Rakefile`, so pin to a recent image and use the `/opt/voxbox/Rakefile` path.

{% include alert.html type="warning" content="These examples use the `:latest` tag for brevity, but for reproducible CI you should pin
to a specific released version rather than tracking `:latest`, which can change underneath you.
Just confirm the tag you pin uses the `/opt/voxbox/Rakefile` layout: older images keep the Rakefile at `/Rakefile`.
Run the container with no arguments (`rake -T`) to list its tasks and check." %}

GitLab can also ingest VoxBox output as native reports.
For a [code quality report](https://docs.gitlab.com/ci/testing/code_quality/):

```yaml
code-quality:
  image:
    name: ghcr.io/voxpupuli/voxbox:latest
    entrypoint: [""]
  stage: lint
  script:
    - bundle exec rake -f /opt/voxbox/Rakefile voxpupuli:custom:lint_all
  variables:
    CODECLIMATE_REPORT_FILE: "gl-code-quality-report.json"
  artifacts:
    when: always
    reports:
      codequality: gl-code-quality-report.json
    expire_in: 1 week
```

For [unit test (JUnit) reports](https://docs.gitlab.com/ci/testing/unit_test_reports/), add the formatter to your `.rspec`:

```text
--format RspecJunitFormatter
--out rspec.xml
```

Then add the job:

```yaml
rspec:
  image:
    name: ghcr.io/voxpupuli/voxbox:latest
    entrypoint: [""]
  stage: test
  script:
    - bundle exec rake -f /opt/voxbox/Rakefile spec
  artifacts:
    when: always
    reports:
      junit: rspec.xml
    expire_in: 1 week
```

## Troubleshooting

### `Don't know how to build task 'sh'`

```text
rake aborted!
Don't know how to build task 'sh' (See the list of available tasks with rake --tasks)
```

This means the image entrypoint swallowed your job's `script:`.
GitLab passed `sh` to the container entrypoint (`bundle exec rake -f /opt/voxbox/Rakefile`), which interpreted it as a rake task name.
It is not caused by a shell script in your repository, so renaming files won't help.

Fix it by blanking the entrypoint in your job's `image:` block:

```yaml
image:
  name: ghcr.io/voxpupuli/voxbox:latest
  entrypoint: [""]
```

If you still see a "no such file" error for the Rakefile, confirm you're pointing at `/opt/voxbox/Rakefile` rather than the legacy `/Rakefile` path.

## Validating a pipeline locally

You can reproduce and verify the GitLab setup on your own machine, without pushing to GitLab, using [`gitlab-ci-local`](https://github.com/firecow/gitlab-ci-local).
A working sample harness (a minimal module plus a corrected `.gitlab-ci.yml`) lives in the [container-voxbox repository](https://github.com/voxpupuli/container-voxbox).

```console
brew install gitlab-ci-local
gitlab-ci-local lint:puppet
```
