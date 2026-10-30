# frozen_string_literal: true

# Hand-written highlights for generated release-notes entries. Each file
# _release_highlights/<nav>/<version>.md (for example
# _release_highlights/openvox-server_9x/9.2.0.md) holds the Markdown that
# _includes/release_notes.html renders under that release's generated heading,
# date, and GitHub link. Optional front matter sets `type` to replace the
# generated release type (for example `type: security`).
#
# The files sit outside the collections so they never render as pages of their
# own; this hook exposes them as site.data.release_highlights[nav][version]. A
# file with no generated entry to attach to (a typo in the version, or a release
# older than the page's `release_notes_after`) is reported, since it would
# otherwise never appear.
module OpenvoxDocs
  module ReleaseHighlights
    DIR = '_release_highlights'

    def self.load(site)
      highlights = {}
      Dir.glob(File.join(site.source, DIR, '*', '*.md')).each do |path|
        nav = File.basename(File.dirname(path))
        version = File.basename(path, '.md')
        (highlights[nav] ||= {})[version] = read(path)
      end
      site.data['release_highlights'] = highlights
      report_unmatched(highlights, site.data['release_notes'] || {})
    end

    def self.read(path)
      content = File.read(path)
      match = Jekyll::Document::YAML_FRONT_MATTER_REGEXP.match(content)
      return { 'body' => content.strip } unless match

      front_matter = YAML.safe_load(match[1]) || {}
      front_matter.merge('body' => match.post_match.strip)
    end

    def self.report_unmatched(highlights, entries)
      highlights.each do |nav, versions|
        generated = Array(entries[nav]).map { |entry| entry['version'] }
        (versions.keys - generated).each do |version|
          Jekyll.logger.warn 'Release highlights:', "#{DIR}/#{nav}/#{version}.md has no generated entry"
        end
      end
    end
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  OpenvoxDocs::ReleaseHighlights.load(site)
end
