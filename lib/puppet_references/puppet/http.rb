# frozen_string_literal: true

require 'puppet_references'
require 'fileutils'
module PuppetReferences
  module Puppet
    class Http < PuppetReferences::Reference
      API_SOURCE = PuppetReferences::PUPPET_DIR + 'api'

      def initialize(*)
        super
        @latest = "#{@latest}/http_api"
      end

      def docs_dir
        collection_dir + 'http_api'
      end

      def build_all
        docs_dir.mkpath
        puts 'HTTP API: Building all...'
        copy_schemas
        copy_docs
        puts 'HTTP API: Done!'
      end

      def copy_schemas
        # This cp_r method is finicky and makes me long for rsync.
        FileUtils.cp_r((API_SOURCE + 'schemas').to_path, collection_dir.to_path)
      end

      def copy_docs
        docs_dir = API_SOURCE + 'docs'
        files = Pathname.glob(docs_dir + '*')
        files.each do |file|
          munge_and_copy_doc_file(file)
        end
      end

      # expects a Pathname
      def munge_and_copy_doc_file(file)
        shortname = file.basename(file.extname).to_path
        title = if shortname == 'http_api_index'
                  'Index'
                elsif shortname == 'pson'
                  'PSON'
                else
                  shortname.sub(/^http_/, '').split('_').map(&:capitalize).join(' ')
                end
        header_data = { title: "Puppet HTTP API: #{title}",
                        canonical: "#{@latest}/#{shortname}.html", }
        content = make_header(header_data, 'OpenVox', PuppetReferences.version_commit) + file.read
        dest = docs_dir + file.basename
        dest.open('w') { |f| f.write(content) }
      end
    end
  end
end
