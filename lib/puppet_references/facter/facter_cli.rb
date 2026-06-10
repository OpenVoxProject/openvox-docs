# frozen_string_literal: true

require 'puppet_references'
module PuppetReferences
  module Facter
    class FacterCli < PuppetReferences::Reference
      def header_data
        { title: 'Facter: CLI',
          toc: 'columns',
          canonical: "#{@latest}/cli.html", }
      end

      def build_all
        require 'open3'
        puts 'Building CLI documentation page for facter.'
        collection_dir.mkpath
        Bundler.with_unbundled_env do
          Open3.capture3("BUNDLE_GEMFILE=#{PuppetReferences::FACTER_DIR}/Gemfile bundle update")
        end
        raw_text, err, exit_code = Open3.capture3("BUNDLE_GEMFILE=#{PuppetReferences::FACTER_DIR}/Gemfile bundle exec facter man")
        if exit_code != 0
          puts "Encountered an error while building the facter cli docs, will abort: #{err}"
          return
        end
        markdown_text, = Open3.capture3('mandoc -T markdown', stdin_data: raw_text)
        # Strip the "TITLE - Manual" header line and the dated footer line mandoc adds
        markdown_text = markdown_text.lines[1...-1].join
        content = make_header(header_data, 'OpenFact', PuppetReferences.version_commit) + markdown_text
        filename = collection_dir + 'cli.md'
        filename.open('w') { |f| f.write(content) }
        puts 'CLI documentation is done!'
      end

      def build_v3_cli
        collection_dir.mkpath
        filename = collection_dir + 'cli.md'
        man_filepath = PuppetReferences::FACTER_DIR + 'man/man8/facter.8'
        raw_text = PuppetReferences::Util.convert_man(man_filepath)
        content = make_header(header_data, 'OpenFact', PuppetReferences.version_commit) + raw_text
        filename.open('w') { |f| f.write(content) }
      end
    end
  end
end
