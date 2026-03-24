# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'rake'

$LOAD_PATH.unshift(File.join(__dir__, 'lib'))

require 'rubocop/rake_task'

RuboCop::RakeTask.new do |task|
  task.plugins << 'rubocop-rake'
end

desc 'List the available groups of references. Run `rake references:<GROUP>` to build.'
task :references do
  puts 'The following references are available:'
  puts 'bundle exec rake references:puppet VERSION=<GIT TAG OR COMMIT>'
  puts 'bundle exec rake references:facter VERSION=<GIT TAG OR COMMIT>'
  puts 'bundle exec rake references:version_tables'
end

namespace :references do
  task puppet: 'references:check_version' do
    require 'puppet_references'
    PuppetReferences.build_puppet_references(ENV.fetch('VERSION', nil))
  end

  task facter: 'references:check_version' do
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
