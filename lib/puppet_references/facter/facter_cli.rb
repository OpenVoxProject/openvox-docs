# frozen_string_literal: true

require 'puppet_references'
module PuppetReferences
  module Facter
    class FacterCli < PuppetReferences::Reference
      OUTPUT_DIR = PuppetReferences::OUTPUT_DIR + 'facter'
      PREAMBLE_FILE = Pathname.new(__FILE__).dirname + 'facter_cli_preamble.md'
      PREAMBLE = PREAMBLE_FILE.read

      def initialize(*)
        @latest = '/puppet/latest'
        super
      end

      def header_data
        { title: 'Facter: CLI',
          toc: 'columns',
          canonical: "#{@latest}/cli.html", }
      end

      def build_all
        puts 'Building CLI documentation page for facter.'
        OUTPUT_DIR.mkpath
        man_filepath = PuppetReferences::FACTER_DIR + 'man/man1/facter.1'
        raw_text = PuppetReferences::Util.convert_man(man_filepath)
        content = make_header(header_data) + raw_text
        filename = OUTPUT_DIR + 'cli.md'
        filename.open('w') { |f| f.write(content) }
        puts 'CLI documentation is done!'
      end

      def build_v3_cli
        OUTPUT_DIR.mkpath
        filename = OUTPUT_DIR + 'cli.md'
        man_filepath = PuppetReferences::FACTER_DIR + 'man/man8/facter.8'
        raw_text = PuppetReferences::Util.convert_man(man_filepath)
        content = make_header(header_data) + raw_text
        filename.open('w') { |f| f.write(content) }
      end
    end
  end
end
