# frozen_string_literal: true

require 'puppet_references'
module PuppetReferences
  module Puppet
    class Yard < PuppetReferences::Reference
      def yard_dir
        collection_dir + 'yard'
      end

      def build_all
        puts 'Building YARD references, which always takes a while...'
        PuppetReferences::PuppetCommand.new("yard -o #{yard_dir}").get
        puts 'Done with YARD!'
      end
    end
  end
end
