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

    # The newest stable (non-prerelease) tag, optionally restricted to a release
    # series given as its leading version segments (e.g. [8] for 8.*, [9, 0] for
    # 9.0.*). Raises rather than returning nil so a typo'd series or a repo with
    # no such tags fails the build instead of silently checking out nothing.
    def newest_release(series: nil)
      versions = @repo.tags.map { |t| Gem::Version.new(t.name) rescue Gem::Version.new(0) } # rubocop:disable Style/RescueModifier
                           .reject(&:prerelease?)
      versions = versions.select { |v| v.segments.first(series.size) == series } if series
      raise "#{@name}: no stable release tag matching #{series ? series.join('.') + '.x' : 'any series'}" if versions.empty?

      versions.max.version
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
