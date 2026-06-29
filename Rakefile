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
  puts 'bundle exec rake references:openvox [VERSION=<GIT TAG OR COMMIT> COLLECTION=<DIR> INSTALLPATH=<RELATIVE OR ABSOLUTE PATH>]'
  puts 'bundle exec rake references:openfact [VERSION=<GIT TAG OR COMMIT> COLLECTION=<DIR> INSTALLPATH=<RELATIVE OR ABSOLUTE PATH>]'
  puts 'bundle exec rake references:openbolt [VERSION=<GIT TAG OR COMMIT> COLLECTION=<DIR> INSTALLPATH=<RELATIVE OR ABSOLUTE PATH>]'
  puts '  VERSION can be omitted, uses latest non-prerelease tag; an explicit VERSION builds that exact ref (e.g. a 9.x prerelease)'
  puts '  COLLECTION can be omitted, defaults to the current stable dir per product (e.g. _openvox_latest); set it to build a frozen version (e.g. _openvox_9x)'
  puts '  INSTALLPATH can be omitted, defaults to references_output/'
  puts 'bundle exec rake references:all [INSTALLPATH=<RELATIVE OR ABSOLUTE PATH>]'
  puts '  Builds every pinned product/version from _data/products.yml into its collection'
end

namespace :references do
  task openvox: 'references:check' do
    require 'puppet_references'
    PuppetReferences.build_puppet_references(ENV.fetch('VERSION', nil), collection: ENV.fetch('COLLECTION', '_openvox_latest'))
  end

  task openfact: 'references:check' do
    require 'puppet_references'
    PuppetReferences.build_facter_references(ENV.fetch('VERSION', nil), collection: ENV.fetch('COLLECTION', '_openfact_latest'))
  end

  task openbolt: 'references:check' do
    require 'puppet_references'
    PuppetReferences.build_openbolt_references(ENV.fetch('VERSION', nil), collection: ENV.fetch('COLLECTION', '_openbolt_latest'))
  end

  desc 'Build every pinned product/version from _data/products.yml into its collection'
  task :all do
    versions = YAML.load_file('_data/products.yml')
    installpath = ENV.fetch('INSTALLPATH', nil)

    # Each (product, version) builds in its own subprocess. A fresh process avoids
    # cross-version contamination from load-time output constants and process-level
    # caches (e.g. the Strings JSON cache), and re-resolves bundler cleanly for the
    # vendored repo it checks out. Only products with a `references` task generate
    # reference pages; authored-only products are skipped.
    versions.each do |product_id, product|
      task_name = product['references']
      next unless task_name

      product.fetch('versions', []).each do |version|
        ref = version['ref']
        collection = version['collection']
        unless ref && collection
          warn "references:all: skipping #{product_id} #{version['id']} (missing ref or collection)"
          next
        end

        cmd = ['bundle', 'exec', 'rake', task_name, "VERSION=#{ref}", "COLLECTION=#{collection}"]
        cmd << "INSTALLPATH=#{installpath}" if installpath
        puts "references:all: #{cmd.join(' ')}"
        Bundler.with_unbundled_env { sh(*cmd) }
      end
    end
  end

  # The agent/server/openvoxdb tables are per-OpenVox-series: each writes into a
  # file named for the collection's nav_key (e.g. openvox_8x), so the component-
  # versions page can render its own series via `site.data.<table>[page.nav]` and
  # a future 9.x collection gets its own data file without colliding. The nav_key
  # is derived from SERIES ("8." -> openvox_8x) and overridable with NAV_KEY.
  openvox_nav_key = lambda do
    ENV.fetch('NAV_KEY', "openvox_#{ENV.fetch('SERIES', '8.').gsub(/\D/, '')}x")
  end

  desc 'Generate _data/agent_release_contents/<nav_key>.yml from upstream component pins'
  task :agent_versions do
    require 'puppet_references/release_tables'
    series = ENV.fetch('SERIES', '8.')
    min_version = ENV.fetch('MIN_RELEASE', '8.25.0')
    path = ENV.fetch('AGENT_VERSIONS_DATA', "_data/agent_release_contents/#{openvox_nav_key.call}.yml")
    rows = PuppetReferences::AgentReleaseTable.write_data_file(series:, min_version:, path:)
    puts "Wrote #{rows.size} releases to #{path}"
  end

  desc 'Generate _data/server_release_contents/<nav_key>.yml from upstream component pins'
  task :server_versions do
    require 'puppet_references/release_tables'
    series = ENV.fetch('SERIES', '8.')
    min_version = ENV.fetch('MIN_RELEASE', '8.12.0')
    path = ENV.fetch('SERVER_VERSIONS_DATA', "_data/server_release_contents/#{openvox_nav_key.call}.yml")
    rows = PuppetReferences::ServerReleaseTable.write_data_file(series:, min_version:, path:)
    puts "Wrote #{rows.size} releases to #{path}"
  end

  desc 'Generate _data/openvoxdb_release_contents/<nav_key>.yml from upstream releases'
  task :openvoxdb_versions do
    require 'puppet_references/release_tables'
    series = ENV.fetch('SERIES', '8.')
    min_version = ENV.fetch('MIN_RELEASE', '8.12.0')
    path = ENV.fetch('OPENVOXDB_VERSIONS_DATA', "_data/openvoxdb_release_contents/#{openvox_nav_key.call}.yml")
    rows = PuppetReferences::OpenvoxdbReleaseTable.write_data_file(series:, min_version:, path:)
    puts "Wrote #{rows.size} releases to #{path}"
  end

  desc 'Generate _data/openbolt_release_contents.yml from upstream component pins'
  task :openbolt_versions do
    require 'puppet_references/release_tables'
    # OpenBolt is on its own 5.x line, independent of the OpenVox major, so it uses
    # its own OPENBOLT_SERIES / OPENBOLT_MIN_RELEASE rather than the generic
    # SERIES / MIN_RELEASE. That keeps an OpenVox 9.x regeneration (SERIES=9.) from
    # leaking into OpenBolt, where it would resolve no 9.x releases and abort.
    # The floor is 5.3.0 because OpenBolt SBOMs begin there; 5.1.0/5.2.0 predate the
    # SBOMs and would only be skipped.
    series = ENV.fetch('OPENBOLT_SERIES', '5.')
    min_version = ENV.fetch('OPENBOLT_MIN_RELEASE', '5.3.0')
    path = ENV.fetch('OPENBOLT_VERSIONS_DATA', '_data/openbolt_release_contents.yml')
    rows = PuppetReferences::OpenboltReleaseTable.write_data_file(series:, min_version:, path:)
    puts "Wrote #{rows.size} releases to #{path}"
  end

  desc 'Generate all component-version data files (agent, server, openvoxdb, openbolt)'
  task component_versions: %i[agent_versions server_versions openvoxdb_versions openbolt_versions]

  desc 'Generate _data/supported_platforms.yml from the shared-actions platforms.json'
  task :supported_platforms do
    require 'puppet_references/supported_platforms'
    path = ENV.fetch('SUPPORTED_PLATFORMS_DATA', '_data/supported_platforms.yml')
    data = PuppetReferences::SupportedPlatforms.write_data_file(path:)
    puts "Wrote #{data.values.sum(&:size)} platform rows across #{data.size} series to #{path}"
  end

  task :check do
    puts 'No VERSION given to build references for - using latest tag' unless ENV['VERSION']
    puts "Building into collection #{ENV.fetch('COLLECTION')}" if ENV['COLLECTION']
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
