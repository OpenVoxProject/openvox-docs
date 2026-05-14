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
  puts 'bundle exec rake references:openvox [VERSION=<GIT TAG OR COMMIT> INSTALLPATH=<RELATIVE OR ABSOLUTE PATH>]'
  puts 'bundle exec rake references:openfact [VERSION=<GIT TAG OR COMMIT> INSTALLPATH=<RELATIVE OR ABSOLUTE PATH>]'
  puts 'bundle exec rake references:openbolt [VERSION=<GIT TAG OR COMMIT> INSTALLPATH=<RELATIVE OR ABSOLUTE PATH>]'
  puts 'bundle exec rake references:version_tables'
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

  task :version_tables do
    require 'puppet_references'
    PuppetReferences.build_version_tables
  end

  task :check do
    puts 'No VERSION given to build references for - using latest tag' unless ENV['VERSION']
    puts "Using provided install path #{ENV.fetch('INSTALLPATH')} instead of default" if ENV['INSTALLPATH']
    puts "Using default install path 'references_output'" unless ENV['INSTALLPATH']
  end
end
