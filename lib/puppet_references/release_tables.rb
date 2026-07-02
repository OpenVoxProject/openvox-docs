# frozen_string_literal: true

require 'json'
require 'yaml'
require 'fileutils'
require 'net/http'
require 'uri'

module PuppetReferences
  # Base for the component "release contents" tables rendered on the OpenVox
  # component-versions page. Each subclass names the upstream repo whose releases
  # drive the table and resolves one row per stable release from authoritative,
  # structured metadata, so the tables are never hand-maintained. The shared
  # GitHub releases/contents plumbing lives here so the per-table classes stay
  # small. Every table now sources its bundled-component columns from
  # openvox-sbom-tools SBOMs (see SbomReleaseTable).
  #
  # Authenticates with ENV GITHUB_TOKEN/GH_TOKEN, falling back to `gh auth token`
  # for local runs. A release whose components can't be resolved (e.g. a tag that
  # predates the data this table reads) is skipped with a warning; transient API
  # failures raise so a bad run never overwrites the committed data file.
  class ReleaseTable
    API_ROOT = 'https://api.github.com'
    USER_AGENT = 'openvox-docs-release-table'

    # A resolved component value must look like a dotted version. This screens out
    # boundary releases that pin a component by git SHA or whose layout yields a
    # blank, so a table only ever shows fully-resolved rows.
    VERSION_RE = /\A\d+(?:\.\d+)+\z/

    class NotFound < StandardError; end

    # Resolve and write the data file consumed by the docs page. Returns the rows.
    def self.write_data_file(series:, min_version:, path:)
      data = new.rows(series: series, min_version: min_version)
      raise 'resolved no releases; refusing to overwrite data file' if data.empty?

      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, data.to_yaml)
      data
    end

    def rows(series:, min_version:)
      cache = {}
      release_tags(series: series, min_version: min_version).filter_map do |tag|
        validate(row_for(tag, cache))
      rescue NotFound => e
        warn "skipping #{tag}: missing #{e.message}"
        nil
      end
    end

    # The upstream repo whose stable releases key the table (e.g. "OpenVoxProject/openvox").
    def repo
      raise NotImplementedError, "#{self.class} must define #repo"
    end

    # Build a row hash for a release tag, or raise NotFound to skip it. The shared
    # cache is keyed however the subclass likes (e.g. by runtime version).
    def row_for(_tag, _cache)
      raise NotImplementedError, "#{self.class} must define #row_for"
    end

    private

    # Fields exempt from the dotted-version check (e.g. a dependency requirement
    # like "~> 8.0" that is intentionally a range, not a resolved version).
    # Subclasses override to allowlist such fields.
    def freeform_fields
      []
    end

    # Every field except the release (and any freeform fields) must resolve to a
    # clean dotted version.
    def validate(row)
      row.each do |field, value|
        next if field == 'release' || freeform_fields.include?(field) || value.to_s.match?(VERSION_RE)

        raise NotFound, "clean #{field} version (got #{value.inspect})"
      end
      row
    end

    # Stable release tags for the series (e.g. "8.") at or above min_version,
    # newest first.
    def release_tags(series:, min_version:)
      floor = Gem::Version.new(min_version)
      # Only the first page (100 newest releases) is read. Safe while min_version
      # stays near the newest releases; revisit with pagination if a series ever
      # has more than 100 releases above the floor.
      body = api_get("/repos/#{repo}/releases?per_page=100", accept: 'application/vnd.github+json')
      JSON.parse(body)
          .reject { |r| r['prerelease'] || r['draft'] }
          .map { |r| r['tag_name'] }
          .select { |t| t.start_with?(series) && Gem::Version.correct?(t) && Gem::Version.new(t) >= floor }
          .sort_by { |t| Gem::Version.new(t) }
          .reverse
    end

    def json_at(repo, path, ref)
      JSON.parse(raw(repo, path, ref))
    end

    def raw(repo, path, ref)
      api_get("/repos/#{repo}/contents/#{path}?ref=#{ref}", accept: 'application/vnd.github.raw')
    end

    def api_get(path, accept:)
      uri = URI("#{API_ROOT}#{path}")
      req = Net::HTTP::Get.new(uri)
      req['User-Agent'] = USER_AGENT
      req['Accept'] = accept
      req['Authorization'] = "Bearer #{token}" unless token.empty?

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
      return res.body if res.is_a?(Net::HTTPSuccess)
      raise NotFound, path if res.is_a?(Net::HTTPNotFound)

      raise "GitHub API #{res.code} for #{path}: #{res.body.to_s[0, 200]}"
    end

    def token
      @token ||= [ENV.fetch('GITHUB_TOKEN', nil), ENV.fetch('GH_TOKEN', nil), `gh auth token 2>/dev/null`.strip]
                 .compact.find { |candidate| !candidate.empty? } || ''
    end
  end

  # Base for tables sourced from openvox-sbom-tools CycloneDX SBOMs rather than
  # scraping upstream pkg-DSL. Each release ships an SBOM committed at
  # lib/openvox/sbom-tools/sbom/<package>_<version>.cdx.json whose `.components[]`
  # carry already-resolved `{name, version}` pairs; a subclass maps the component
  # names it cares about to the table's columns. A release whose SBOM has not been
  # committed yet is skipped (NotFound), so the table tracks SBOM availability:
  # a newly tagged release appears once its SBOM lands upstream.
  class SbomReleaseTable < ReleaseTable
    SBOM_REPO = 'OpenVoxProject/openvox-sbom-tools'
    SBOM_DIR = 'lib/openvox/sbom-tools/sbom'

    # SBOM package name; the file for a release is "<package>_<tag>.cdx.json".
    def sbom_package
      raise NotImplementedError, "#{self.class} must define #sbom_package"
    end

    # Ordered { column => component-name } map pulled from each release's SBOM.
    # Insertion order sets the column order of the generated row.
    def columns
      raise NotImplementedError, "#{self.class} must define #columns"
    end

    def row_for(tag, _cache)
      resolved = sbom_components(tag)
      row = { 'release' => tag }
      columns.each do |column, name|
        version = resolved[name]
        raise NotFound, "component #{name.inspect} in #{sbom_package} #{tag} SBOM" unless version

        row[column] = version
      end
      row
    end

    private

    # { component-name => version } for every component in a release's SBOM. The
    # underlying GitHub contents fetch raises NotFound when the SBOM file is absent
    # (a release without a committed SBOM), which skips the release.
    def sbom_components(tag)
      sbom = json_at(SBOM_REPO, "#{SBOM_DIR}/#{sbom_package}_#{tag}.cdx.json", 'main')
      sbom.fetch('components').to_h { |component| [component['name'], component['version']] }
    end
  end

  # openvox-agent: bundled OpenFact plus Ruby/OpenSSL/curl from the agent runtime,
  # read from the openvox-agent SBOM. The SBOM lists both `openssl` and
  # `openssl-fips`; we report the `openssl` runtime version to match the column.
  class AgentReleaseTable < SbomReleaseTable
    REPO = 'OpenVoxProject/openvox'

    def repo
      REPO
    end

    def sbom_package
      'openvox-agent'
    end

    def columns
      { 'openfact' => 'openfact', 'ruby' => 'ruby', 'openssl' => 'openssl', 'curl' => 'curl' }
    end
  end

  # OpenBolt ships on its own 5.x line and bundles its own runtime (Ruby/OpenSSL
  # plus r10k) along with OpenVox itself (for `bolt apply`). The SBOM reports the
  # exact bundled OpenVox version resolved at build time, so the `openvox` column
  # is the resolved version rather than the gemspec requirement range.
  class OpenboltReleaseTable < SbomReleaseTable
    REPO = 'OpenVoxProject/openbolt'

    def repo
      REPO
    end

    def sbom_package
      'openbolt'
    end

    def columns
      { 'openvox' => 'openvox', 'ruby' => 'ruby', 'openssl' => 'openssl', 'r10k' => 'r10k' }
    end
  end

  # openvox-server: bundled JRuby, read from the openvox-server SBOM's `jruby-base`
  # component (the resolved JRuby version). This replaces the previous resolution
  # through the server's pinned jruby-utils -> jruby-deps in project.clj, which
  # required stripping a "-N" packaging suffix; `jruby-base` is already clean. Java
  # is a supported requirement, not a pin, so it is hand-maintained on the docs
  # page rather than resolved here.
  class ServerReleaseTable < SbomReleaseTable
    REPO = 'OpenVoxProject/openvox-server'

    def repo
      REPO
    end

    def sbom_package
      'openvox-server'
    end

    def columns
      { 'jruby' => 'jruby-base' }
    end
  end

  # OpenVoxDB ships on its own independent version line. It is a Clojure/JVM
  # service (no bundled JRuby), so the one bundled component worth surfacing is the
  # embedded Jetty HTTP server, read from its per-release SBOM. Java and PostgreSQL
  # are supported requirements (the openvoxdb module only declares a postgresql
  # dependency range, not a bundled version), so those columns stay hand-maintained
  # on the docs page.
  class OpenvoxdbReleaseTable < SbomReleaseTable
    def repo
      'OpenVoxProject/openvoxdb'
    end

    def sbom_package
      'openvoxdb'
    end

    def columns
      { 'jetty' => 'jetty-server' }
    end
  end
end
