# frozen_string_literal: true

# Every numbered collection whose version *is* its product's `latest` alias
# (e.g. _openvox_8x while `latest: 8x`) publishes byte-identical content twice:
# once under its own base (/openvox/8.x/) and once under /openvox/latest/ via
# the _latest symlink. This hook points the numbered copy's canonical at its
# /latest/ twin so search engines index the stable /latest/ URLs; the theme's
# head.html (and jekyll-seo-tag, if adopted) emit page.canonical_url when set.
#
# Frozen older versions are deliberately left alone with the theme's default
# self-canonical: once `latest` moves on, their content is unique and the
# same page may not exist under /latest/.
#
# The origin is hardcoded, matching llms.txt, because site.url is unset.
module OpenvoxDocs
  module CanonicalLatest
    ORIGIN = 'https://docs.openvoxproject.org'

    def self.apply(site)
      (site.data['products'] || {}).each do |product_id, product|
        version = Array(product['versions']).find { |v| v['id'] == product['latest'] }
        next unless version

        collection = site.collections[version['collection'].delete_prefix('_')]
        next if collection.nil? || collection.label.end_with?('_latest')

        canonicalize(collection, version['base'], "/#{product_id}/latest/")
      end
    end

    def self.canonicalize(collection, base, latest_base)
      collection.docs.each do |doc|
        next unless doc.url.start_with?(base)

        doc.data['canonical_url'] = "#{ORIGIN}#{latest_base}#{doc.url.delete_prefix(base)}"
      end
    end
  end
end

Jekyll::Hooks.register :site, :pre_render do |site|
  OpenvoxDocs::CanonicalLatest.apply(site)
end
