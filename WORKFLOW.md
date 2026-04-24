# Generating and Updating documentation.

## Configuration

The central config is located in `source/_config.yml`.

Here we set the different sources for documentation.

e.g.

- Puppet documentatoin is in this repo
- PuppetDB documentatoin is in puppetdb repo (external source)

## File Structure

In `source` directory on can find the versions and the content.

e.g.

```text
source/
  |- puppet/
  |    |- 4.4/
  |    \- 8.25/
  \- facter/
       |- 3.8/
       \- 5.5
```

Only versions found in this directory are generated.

## Generating new documentation

### Base documentation

```shell
bundle config set --path vendor
bundle install
bundle exec rake generate
```

This generates:

- the `output` folder, based on the content of the `source` folder and the `swource/_config.yml` file..
- the `externalsources` folder based on the  config setting.

### References

```shell
bundle exec rake references:puppet VERSION=8.25.0
bundle exec rake references:facter VERSION=5.5.0
```

This clones puppet and facter into the `vendor` directory and generates the `references_output` directory based on the provided version.

## Moving stuff in place

Copy the output from `references_output/facter` to `source/facter/latest`

Copy the output from `references_output/puppet` to `source/puppet/latest`

Run `bundle exec rake generate` to generate the new content.

Run `bundle exec rake serve` and open a browser at `http://localhost:9292`

