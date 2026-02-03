require 'puppet_references'
require 'fileutils'
module PuppetReferences
  module Puppet
    class Http < PuppetReferences::Reference
      OUTPUT_DIR = PuppetReferences::OUTPUT_DIR + 'puppet'
      DOCS_DIR = OUTPUT_DIR + 'http_api'
      API_SOURCE = PuppetReferences::PUPPET_DIR + 'api'

      def initialize(*)
        @latest = '/puppet/latest/http_api'
        super
      end

      def build_all
        DOCS_DIR.mkpath
        puts 'HTTP API: Building all...'
        copy_schemas
        copy_docs
        puts 'HTTP API: Done!'
      end

      def copy_schemas
        # This cp_r method is finicky and makes me long for rsync.
        FileUtils.cp_r((API_SOURCE + 'schemas').to_path, OUTPUT_DIR.to_path)
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
        content = make_header(header_data) + file.read
        dest = DOCS_DIR + file.basename
        dest.open('w') { |f| f.write(content) }
      end
    end
  end
end
