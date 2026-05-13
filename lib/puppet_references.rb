# frozen_string_literal: true

require 'pathname'

module PuppetReferences
  class << self
    attr_reader :version_commit
  end

  BASE_DIR = Pathname.new(File.expand_path(__FILE__)).parent.parent
  PUPPET_DIR = BASE_DIR + 'vendor/openvox'
  FACTER_DIR = BASE_DIR + 'vendor/openfact'
  AGENT_DIR = BASE_DIR + 'vendor/openvox-agent'
  BOLT_DIR = BASE_DIR + 'vendor/openbolt'
  INSTALLPATH = ENV['INSTALLPATH'] ? ENV.fetch('INSTALLPATH') : 'references_output'
  OUTPUT_DIR = BASE_DIR + INSTALLPATH

  require 'puppet_references/config'
  require 'puppet_references/util'
  require 'puppet_references/repo'
  require 'puppet_references/reference'
  require 'puppet_references/doc_command'
  require 'puppet_references/man_command'
  require 'puppet_references/puppet/puppet_doc'
  require 'puppet_references/puppet/strings'
  require 'puppet_references/puppet/man'
  require 'puppet_references/puppet/type'
  require 'puppet_references/puppet/type_strings'
  require 'puppet_references/puppet/functions'
  require 'puppet_references/facter/core_facts'
  require 'puppet_references/facter/facter_cli'
  require 'puppet_references/openbolt/docs'
  require 'puppet_references/version_tables/config'
  require 'puppet_references/version_tables/data/pe'
  require 'puppet_references/version_tables/data/agent'

  def self.build_puppet_references(commit)
    references = [
      PuppetReferences::Puppet::Man,
      PuppetReferences::Puppet::PuppetDoc,
      PuppetReferences::Puppet::Type,
      PuppetReferences::Puppet::TypeStrings,
      PuppetReferences::Puppet::Functions,
    ]
    config = PuppetReferences::Config.read
    repo = PuppetReferences::Repo.new('openvox', PUPPET_DIR, nil, config['puppet']['repo'])
    @version_commit = commit || repo.describe.split('-')[0]
    puts "Using tag #{@version_commit}"
    real_commit = repo.checkout(@version_commit)
    repo.update_bundle
    build_from_list_of_classes(references, real_commit)
  end

  def self.build_openbolt_references
    config = PuppetReferences::Config.read
    bolt_config = config.fetch('openbolt', {})
    repo = PuppetReferences::Repo.new('openbolt', BOLT_DIR, nil, bolt_config.fetch('repo', {}))
    real_commit = repo.checkout(bolt_config.fetch('version', 'main'))
    repo.update_bundle
    ref = PuppetReferences::Openbolt::Docs.new(real_commit)
    ref.build_all
  end

  def self.semantic?(string)
    Gem::Version.correct?(string)
  end

  def self.build_facter_references(commit)
    references = [
      PuppetReferences::Facter::CoreFacts,
    ]
    # Adding this workaround so the build doesn't fail for 3.y. Check with Claire to see if
    # we need the CLI docs for 3.y. We can remove this when we stop building 3.y.
    version4 = Gem::Version.create('4.0.0')
    repo = PuppetReferences::Repo.new('openfact', FACTER_DIR)
    @version_commit = commit || repo.describe.split('-')[0]
    puts "Using tag #{@version_commit}"
    real_commit = repo.checkout(@version_commit)
    repo.update_bundle
    if !semantic?(@version_commit) || (semantic?(@version_commit) && Gem::Version.create(@version_commit) >= version4)
      references << PuppetReferences::Facter::FacterCli
    elsif semantic?(@version_commit) && Gem::Version.create(@version_commit) < version4
      reference = PuppetReferences::Facter::FacterCli.new(real_commit)
      reference.build_v3_cli
    end
    build_from_list_of_classes(references, real_commit)
  end

  def self.build_from_list_of_classes(reference_classes, real_commit)
    references = reference_classes.map { |r| r.new(real_commit) }
    references.each(&:build_all)

    locations = references.map do |ref|
      "#{ref.class} -> #{ref.latest}"
    end.join("\n")
    puts 'NOTE: Generated files are in the references_output directory.'
    puts "NOTE: You'll have to move the generated files into place yourself. The 'latest' location for each is:"
    puts locations
  end
end
