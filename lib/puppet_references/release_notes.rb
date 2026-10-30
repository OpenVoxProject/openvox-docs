# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'puppet_references/release_tables'

module PuppetReferences
  # The generated part of each release-notes entry: version, release date, GitHub
  # release link, default release type, and the bundled components that changed
  # since the previous release in the series, read from the openvox-sbom-tools
  # SBOMs. _includes/release_notes.html renders these records, newest first, above
  # the hand-written entries on a release-notes page; hand-written highlights for
  # a release live in _release_highlights/<nav>/<version>.md (see
  # _plugins/release_highlights.rb).
  #
  # Which pages generate entries is set in _data/products.yml: a product's
  # `release_notes` block names its GitHub repo and SBOM package, and each version
  # with `release_notes_after` gets entries for the stable releases in its series
  # newer than that version. Older releases keep their hand-written entries.
  class ReleaseNotes < SbomReleaseTable
    # Write _data/release_notes/<nav>.yml for every configured version. A version
    # that fails (for example a GitHub API error) keeps its committed data file and
    # is reported in the returned list, so one failure never blanks another page.
    def self.write_all(products:, dir:)
      products.each_value.flat_map do |product|
        config = product['release_notes']
        next [] unless config

        product['versions'].filter_map do |version|
          after = version['release_notes_after']
          next unless after

          nav = version['collection'].delete_prefix('_')
          path = File.join(dir, "#{nav}.yml")
          begin
            notes = new(repo: config['repo'], sbom_package: config['sbom'])
            entries = notes.entries(series: version['label'].delete_suffix('x'), after: after)
            FileUtils.mkdir_p(dir)
            File.write(path, entries.to_yaml)
            puts "Wrote #{entries.size} release-notes entries to #{path}"
            nil
          rescue StandardError => e
            warn "release notes for #{nav} failed (#{e.message}); keeping #{path}"
            nav
          end
        end
      end
    end

    attr_reader :repo, :sbom_package

    def initialize(repo:, sbom_package:)
      super()
      @repo = repo
      @sbom_package = sbom_package
    end

    # Records for the stable releases in the series newer than `after`, newest first.
    def entries(series:, after:)
      floor = Gem::Version.new(after)
      releases = stable_releases(series: series).sort_by { |r| Gem::Version.new(r['tag_name']) }
      releases.each_with_index.filter_map do |release, i|
        next unless Gem::Version.new(release['tag_name']) > floor

        entry(release, i.positive? ? releases[i - 1]['tag_name'] : nil)
      end.reverse
    end

    private

    # A minor or major release (x.y.0) defaults to a feature release, anything else
    # to a bug-fix release; a highlights file can override `type`, for example to
    # `security`. The date is the GitHub release's publication date in UTC.
    def entry(release, previous)
      tag = release['tag_name']
      record = {
        'version' => tag,
        'date' => release['published_at'][0, 10],
        'url' => release['html_url'],
        'type' => Gem::Version.new(tag).segments[2].to_i.zero? ? 'feature' : 'bug-fix',
      }
      changes = previous && component_changes(previous, tag)
      if changes&.any?
        record['previous'] = previous
        record['components'] = changes
      end
      record
    end

    # Components whose version differs between two releases' SBOMs, sorted by name.
    # A component only in the newer SBOM has no `from`; one only in the older has
    # no `to`. Nil when either SBOM has not been published yet, so the entry renders
    # without the table until the SBOM lands and the next build picks it up.
    def component_changes(from_tag, to_tag)
      before = sbom_components(from_tag)
      after = sbom_components(to_tag)
      (before.keys | after.keys).sort.filter_map do |name|
        next if before[name] == after[name]

        { 'name' => name, 'from' => before[name], 'to' => after[name] }.compact
      end
    rescue NotFound => e
      warn "no component changes for #{sbom_package} #{to_tag}: missing #{e.message}"
      nil
    end
  end
end
