# frozen_string_literal: true

require 'puppet_references'
require 'json'
require 'erb'
require 'ostruct'
require 'pathname'

module PuppetReferences
  module Puppet
    class Functions < PuppetReferences::Reference
      TEMPLATE_FILE = Pathname.new(File.expand_path(__FILE__)).dirname + 'functions_template.erb'
      PREAMBLE_FILE = Pathname.new(File.expand_path(__FILE__)).dirname + 'functions_preamble.md'
      PREAMBLE = PREAMBLE_FILE.read

      def build_all
        build_variant('function.md')
      end

      def build_variant(filename, preferred_version = 'ruby4x')
        collection_dir.mkpath
        puts "Functions ref (#{filename}): Building"
        strings_data = PuppetReferences::Puppet::Strings.new(@collection)
        functions = strings_data['puppet_functions']
        header_data = { title: 'Built-in function reference',
                        canonical: "#{@latest}/function.html",
                        toc_levels: 2,
                        toc: 'columns', }

        # Deal with the duplicate function stub situation.
        # 1. Figure out which functions are duplicated.
        names = functions.map { |func| func['name'] }
        duplicates = names.uniq.select { |name| names.count(name) > 1 }
        # 2. Reject the unpreferred version of any dupes.
        functions = functions.reject do |func|
          duplicates.include?(func['name']) && func['type'] != preferred_version
        end

        body = ERB.new(File.read(TEMPLATE_FILE), trim_mode: '-').result_with_hash(functions: functions)
        # This substitution could potentially make things a bit brittle, but it has to be done because the jump
        # From H2s to H4s is causing issues with the DITA-OT, which sees this as a rule violation. If it
        # Does become an issue, we should return to this and figure out a better way to generate the functions doc.
        content = localize_links(make_header(header_data, 'OpenVox', PuppetReferences.version_commit) + "\n\n" + PREAMBLE + "\n\n" + body.gsub(/#####\s(.*?:)/, '**\1**').gsub(
          /####\s/, '###\s'
        ))
        output_path = collection_dir + filename
        output_path.open('w') { |f| f.write(content) }
        puts "Functions ref (#{filename}): Done!"
      end
    end
  end
end
