# frozen_string_literal: true

require 'puppet_references'
module PuppetReferences
  module Facter
    class CoreFacts < PuppetReferences::Reference
      PREAMBLE_FILE = Pathname.new(__FILE__).dirname + 'core_facts_preamble.md'
      PREAMBLE = PREAMBLE_FILE.read

      def build_all
        puts 'Core facts: building reference.'
        collection_dir.mkpath
        raw_text = `ruby #{PuppetReferences::FACTER_DIR}/lib/docs/generate.rb`
        header_data = { title: 'Facter: Core Facts',
                        toc: 'columns',
                        canonical: "#{@latest}/core_facts.html", }
        content = make_header(header_data, 'OpenFact', PuppetReferences.version_commit) + PREAMBLE + raw_text
        filename = collection_dir + 'core_facts.md'
        filename.open('w') { |f| f.write(content) }
        puts 'Core facts: done!'
      end
    end
  end
end
