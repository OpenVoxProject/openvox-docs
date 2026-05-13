# frozen_string_literal: true

require 'puppet_references'
require 'fileutils'

module PuppetReferences
  module Openbolt
    class Docs < PuppetReferences::Reference
      OUTPUT_DIR = PuppetReferences::OUTPUT_DIR + '_openbolt_5x'
      DOCS_SOURCE = PuppetReferences::BOLT_DIR + 'documentation'

      GENERATED_PAGES = %w[
        bolt_cmdlet_reference.md
        bolt_command_reference.md
        bolt_defaults_reference.md
        bolt_project_reference.md
        bolt_transports_reference.md
        bolt_types_reference.md
        packaged_modules.md
        plan_functions.md
        privilege_escalation.md
      ].freeze

      def initialize(*)
        @latest = '/openbolt/latest'
        super
      end

      def build_all
        OUTPUT_DIR.mkpath
        puts 'OpenBolt Docs: Building all...'
        generate_reference_pages
        copy_reference_pages
        copy_images
        puts 'OpenBolt Docs: Done!'
      end

      private

      def generate_reference_pages
        puts 'OpenBolt Docs: Generating ERB reference pages via rake docs:all...'
        Bundler.with_unbundled_env do
          Dir.chdir(PuppetReferences::BOLT_DIR.to_path) do
            system('bundle exec rake docs:all') ||
              raise('openbolt: rake docs:all failed')
          end
        end
      end

      def copy_reference_pages
        GENERATED_PAGES.each do |filename|
          source = DOCS_SOURCE + filename
          unless source.exist?
            warn "openbolt: #{filename} not found, skipping"
            next
          end

          content = rewrite_md_links(source.read)
          dest = OUTPUT_DIR + filename
          dest.open('w') { |f| f.write(content) }
        end
      end

      def copy_images
        Pathname.glob(DOCS_SOURCE + '*.{png,jpg,gif,svg}').each do |img|
          FileUtils.cp(img.to_path, (OUTPUT_DIR + img.basename).to_path)
        end
      end

      # Rewrite relative .md cross-reference links to .html so Jekyll serves
      # them correctly. Skips URLs containing ':' (e.g. https://).
      def rewrite_md_links(content)
        content
          .gsub(/(\]\([^):]*?)\.md((?:#[^)]*)?)\)/, '\1.html\2)')
          .gsub(/\bhref="([^":]*?)\.md((?:#[^"]*)?)"/, 'href="\1.html\2"')
      end
    end
  end
end
