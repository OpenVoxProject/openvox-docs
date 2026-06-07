# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'pathname'
require 'fileutils'
require 'yaml'
require 'rake/clean'

require 'rubocop/rake_task'

RuboCop::RakeTask.new do |task|
  task.plugins << 'rubocop-rake'
end

clobber_dirs = [
  # ceated by references rake sub tasks
  'references_output',
  'vendor/openbolt',
  'vendor/openfact',
  'vendor/openvox',
  '.yardoc',
  # created by running jekyll
  '_site',
  '.jekyll-cache',
]

clobber_dirs.each do |dir|
  CLOBBER.include(dir)
end

desc 'List the available groups of references. Run `rake references:<GROUP>` to build.'
task :references do
  puts 'The following references are available:'
  puts 'bundle exec rake references:openvox [VERSION=<GIT TAG OR COMMIT> INSTALLPATH=<RELATIVE OR ABSOLUTE PATH>]'
  puts 'bundle exec rake references:openfact [VERSION=<GIT TAG OR COMMIT> INSTALLPATH=<RELATIVE OR ABSOLUTE PATH>]'
  puts 'bundle exec rake references:openbolt [VERSION=<GIT TAG OR COMMIT> INSTALLPATH=<RELATIVE OR ABSOLUTE PATH>]'
  puts '  VERSION can be omitted, uses latest tag'
  puts '  INSTALLPATH can be omitted, defaults to references_output/'
end

namespace :references do
  task openvox: 'references:check' do
    require 'puppet_references'
    PuppetReferences.build_puppet_references(ENV.fetch('VERSION', nil))
  end

  task openfact: 'references:check' do
    require 'puppet_references'
    PuppetReferences.build_facter_references(ENV.fetch('VERSION', nil))
  end

  task openbolt: 'references:check' do
    require 'puppet_references'
    PuppetReferences.build_openbolt_references(ENV.fetch('VERSION', nil))
  end

  desc 'Generate _data/agent_release_contents.yml from upstream component pins'
  task :agent_versions do
    require 'puppet_references/agent_release_table'
    series = ENV.fetch('SERIES', '8.')
    min_version = ENV.fetch('MIN_RELEASE', '8.25.0')
    path = ENV.fetch('AGENT_VERSIONS_DATA', '_data/agent_release_contents.yml')
    rows = PuppetReferences::AgentReleaseTable.write_data_file(series:, min_version:, path:)
    puts "Wrote #{rows.size} releases to #{path}"
  end

  task :check do
    puts 'No VERSION given to build references for - using latest tag' unless ENV['VERSION']
    puts "Using provided install path #{ENV.fetch('INSTALLPATH')} instead of default" if ENV['INSTALLPATH']
    puts "Using default install path 'references_output'" unless ENV['INSTALLPATH']
  end
end

namespace :test do
  desc 'Check internal links across all built collections (run after `jekyll build`). ' \
       'Override the build dir with SITE_DIR (default: _site).'
  task :links do
    require 'html-proofer'

    site_dir = ENV.fetch('SITE_DIR', '_site')

    # Each collection's `latest` is a symlink to its current stable version, so
    # scoping to `<collection>/latest` checks every page exactly once and follows
    # the current version automatically as new ones are added.
    collections = %w[
      openvox
      openvox-server
      openvoxdb
      openbolt
      openfact
      ecosystem
      openvox-containers
    ]

    # The OpenBolt generated reference pages 404 site-wide until an openbolt
    # release > 5.5.0 ships the front-matter fix (issue #202). CI builds the
    # newest openbolt release tag, which predates that fix, so these nine pages
    # don't render. They're linked from authored pages *and* the shared theme
    # sidebar (rendered on every collection's pages), so ignore them by basename
    # -- matching the absolute path, a relative path, or an anchored form. Remove
    # this once #202 ships in a release.
    openbolt_202_404s = /(?:
      bolt_command_reference|
      bolt_cmdlet_reference|
      bolt_defaults_reference|
      bolt_project_reference|
      bolt_transports_reference|
      bolt_types_reference|
      packaged_modules|
      plan_functions|
      privilege_escalation
    )\.html/x

    dirs = collections.map { |c| File.join(site_dir, c, 'latest') }

    HTMLProofer.check_directories(
      dirs,
      root_dir: site_dir,
      disable_external: true,
      enforce_https: false,
      ignore_empty_alt: true,
      ignore_urls: [openbolt_202_404s],
      checks: ['Links'],
    ).run
  end
end
