# frozen_string_literal: true

require 'puppet_references'
require 'json'

# @@generated_files class var usage is intentional here: it memoizes which
# strings.json files this process has already generated, so the expensive
# `puppet strings generate` runs once per output collection rather than once per
# Strings instance. Keyed by path so building more than one collection in a
# single process generates each rather than reusing the first.
# rubocop:disable Style/ClassVars
module PuppetReferences
  module Puppet
    class Strings < Hash
      @@generated_files = []

      def initialize(collection = '_openvox_latest', force_cached: false)
        super()
        @json_file = PuppetReferences::OUTPUT_DIR + collection + 'strings.json'
        generate_strings_data unless force_cached || @@generated_files.include?(@json_file.to_s)
        merge!(JSON.parse(File.read(@json_file)))
        # We can't keep the actual data hash in an instance variable, because if you duplicate the main hash, all its
        # deeply nested members will be assigned by reference to the new hash, and you'll get leakage across objects.
      end

      def generate_strings_data
        puts 'Generating Puppet Strings JSON data...'
        @json_file.dirname.mkpath
        rubyfiles = Dir.glob("#{PuppetReferences::PUPPET_DIR}/lib/puppet/**/*.rb")
        system("bundle exec puppet strings generate --format json --out #{@json_file} #{rubyfiles.join(' ')}")
        puts "Strings data: Done! (#{@json_file})"
        @@generated_files << @json_file.to_s
      end
    end
  end
end
# rubocop:enable Style/ClassVars
