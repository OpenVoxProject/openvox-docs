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

CLOBBER.include('references_output')

# top_dir = Dir.pwd

# SOURCE_DIR = "#{top_dir}/source".freeze
# OUTPUT_DIR = "#{top_dir}/output".freeze
# STASH_DIR = "#{top_dir}/_stash".freeze
# PREVIEW_DIR = "#{top_dir}/_preview".freeze

# VERSION_FILE = "#{OUTPUT_DIR}/VERSION.txt".freeze

desc 'List the available groups of references. Run `rake references:<GROUP>` to build.'
task :references do
  puts 'The following references are available:'
  puts 'bundle exec rake references:openvox VERSION=<GIT TAG OR COMMIT>'
  puts 'bundle exec rake references:openfact VERSION=<GIT TAG OR COMMIT>'
  puts 'bundle exec rake references:version_tables'
end

namespace :references do
  task openvox: 'references:check_version' do
    require 'puppet_references'
    PuppetReferences.build_puppet_references(ENV.fetch('VERSION', nil))
  end

  task openfact: 'references:check_version' do
    require 'puppet_references'
    PuppetReferences.build_facter_references(ENV.fetch('VERSION', nil))
  end

  task :version_tables do
    require 'puppet_references'
    PuppetReferences.build_version_tables
  end

  task :check_version do
    abort 'No VERSION given to build references for' unless ENV['VERSION']
  end
end
