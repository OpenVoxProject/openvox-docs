# frozen_string_literal: true

require 'puppet_references'

module PuppetReferences
  class Reference
    attr_accessor :commit, :latest
    attr_reader :collection

    def initialize(commit, collection)
      @commit = commit
      @collection = collection
      @latest = PuppetReferences.url_base_for(collection)
    end

    # Absolute path to the target collection directory under the install path.
    def collection_dir
      PuppetReferences::OUTPUT_DIR + @collection
    end

    # Rewrite this product's own "/<product>/latest/" doc links to the target
    # version's base, so generated pages for a frozen version stay within that
    # version instead of leaking to latest. Links to a *different* product's
    # "/latest/" are left alone — cross-product links follow latest by policy.
    # No-op when building the current latest collection.
    def localize_links(text)
      latest_base = PuppetReferences.url_base_for(@collection.sub(/_[^_]+\z/, '_latest'))
      version_base = PuppetReferences.url_base_for(@collection)
      return text if latest_base == version_base

      text.gsub("#{latest_base}/", "#{version_base}/")
    end

    def make_header(header_data, source, commit)
      default_header_data = { layout: 'default',
                              built_from_commit: @commit, }
      PuppetReferences::Util.make_header(default_header_data.merge(header_data), source, commit)
    end
  end
end
