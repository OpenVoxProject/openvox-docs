# frozen_string_literal: true

require 'puppet_references'
require 'git'

module PuppetReferences
  class Repo
    attr_reader :name, :directory, :source, :repo, :config

    def initialize(name, directory, sources = nil, config = nil)
      @config = config || {}
      @name = name
      @directory = directory
      @sources = if sources
                   [sources].flatten
                 else
                   ["https://github.com/openvoxproject/#{@name}.git"]
                 end
      @main_source = @sources[0]
      unless Dir.exist?(@directory + '.git') || @config['skip_download']
        puts "Cloning #{@name} repo..."
        Git.clone(@main_source, @directory)
        puts 'done cloning.'
      end
      @repo = Git.open(@directory)
      @repo.checkout('remotes/origin/HEAD')
      # fetch the main source
      @repo.fetch unless @config['skip_download']
      # fetch tags from secondary sources
      @sources[1..].each do |source|
        @repo.fetch(source, { tags: true }) unless @config['skip_download']
      end
    end

    def checkout(commit)
      @repo.checkout(commit, { force: true }) unless @config['skip_download']
      @repo.revparse(commit)
    end

    def describe
      @repo.describe
    end

    def tags
      @repo.tags
    end

    def newest_release
      versions = tag_names.filter_map { |name| Gem::Version.new(name) rescue nil } # rubocop:disable Style/RescueModifier
                          .reject(&:prerelease?)
      raise "#{@name}: no stable release tag found" if versions.empty?

      versions.max.version
    end

    # Tag names straight from `git tag --list`. The git gem's tag enumeration
    # (Git::Base#tags) re-resolves every name and, since git 5.x, raises on the
    # literal `tags/2.6.0rc*` tags that exist in the openvox repository, so
    # list the names without validating them; non-version names are discarded
    # by the caller anyway.
    def tag_names
      Dir.chdir(@directory) { `git tag --list`.split("\n") }
    end

    def update_bundle
      Dir.chdir(@directory) do
        if Dir.exist?(@directory + '.bundle/stuff')
          puts "In #{@name} dir: Running bundle update."
          PuppetReferences::Util.run_dirty_command('bundle update')
        else
          puts "In #{@name} dir: Running bundle config set --local path '.bundle/stuff'"
          PuppetReferences::Util.run_dirty_command("bundle config set --local path '.bundle/stuff'")
          puts "In #{@name} dir: Running bundle install"
          PuppetReferences::Util.run_dirty_command('bundle install')
        end
      end
    end
  end
end
