require 'puppet_references'
require 'json'

module PuppetReferences
  module Puppet
    class Strings < Hash
      STRINGS_JSON_FILE = PuppetReferences::OUTPUT_DIR + 'puppet/strings.json'
      @@strings_data_cached = false

      def initialize(force_cached = false)
        super()
        @@strings_data_cached = true if force_cached
        generate_strings_data unless @@strings_data_cached
        merge!(JSON.parse(File.read(STRINGS_JSON_FILE)))
        # We can't keep the actual data hash in an instance variable, because if you duplicate the main hash, all its
        # deeply nested members will be assigned by reference to the new hash, and you'll get leakage across objects.
      end

      def generate_strings_data
        puts 'Generating Puppet Strings JSON data...'
        rubyfiles = Dir.glob("#{PuppetReferences::PUPPET_DIR}/lib/puppet/**/*.rb")
        system("bundle exec puppet strings generate --format json --out #{STRINGS_JSON_FILE} #{rubyfiles.join(' ')}")
        puts "Strings data: Done! (#{STRINGS_JSON_FILE})"
        @@strings_data_cached = true
      end
    end
  end
end
