# frozen_string_literal: true

require 'puppet_references'
require 'yaml'
module PuppetReferences
  module Util
    # Given a hash of data, return YAML frontmatter suitable for the docs site.
    def self.make_header(data, repo, commit)
      # clean out any symbols:
      generated_at = "> **NOTE:** This page was generated from the #{repo} source code based on version #{commit} on #{Time.now}"
      clean_data = data.transform_keys(&:to_s)
      YAML.dump(clean_data) + "---\n\n" + "# #{clean_data['title']}" + "\n\n" + generated_at + "\n\n"
    end

    # Run a command that can't cope with a contaminated shell environment.
    def self.run_dirty_command(command)
      Bundler.with_unbundled_env do
        # Bundler replaces the entire environment once this block is finished.
        ENV.delete('RUBYLIB')
        `#{command}`
      end
    end

    def self.convert_man(man_filepath)
      require 'pandoc-ruby'
      PandocRuby.convert([man_filepath], from: :man, to: :markdown)
                .gsub(/#(.*?)\n/, '##\1')
                .gsub(/:\s\s\s\n\n```\{=html\}\n<!--\s-->\n```/, '')
                .gsub(/\n:\s\s\s\s/, '')
    end
  end
end
