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
  # structured component pins, so the tables are never hand-maintained. The shared
  # GitHub releases/contents plumbing lives here so the per-table classes stay small.
  #
  # Authenticates with ENV GITHUB_TOKEN/GH_TOKEN, falling back to `gh auth token`
  # for local runs. A release whose component layout can't be resolved (e.g. very
  # old tags that predate these pins) is skipped with a warning; transient API
  # failures raise so a bad run never overwrites the committed data file.
  class ReleaseTable
    API_ROOT = 'https://api.github.com'
    USER_AGENT = 'openvox-docs-release-table'
    RUNTIME_REPO = 'OpenVoxProject/puppet-runtime'

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

    # Files under puppet-runtime's configs/components at a given runtime version.
    def runtime_files(runtime_ver)
      list_dir(RUNTIME_REPO, 'configs/components', runtime_ver)
    end

    # Component version from puppet-runtime's <name>.json (.version) or the vanagon
    # <name>.rb DSL. Recent components pin in JSON; older ones use the .rb DSL.
    def component_version(pattern, runtime_ver, files)
      if (json = files.find { |n| n.match?(/\A#{pattern}\.json\z/) })
        return json_at(RUNTIME_REPO, "configs/components/#{json}", runtime_ver)['version']
      end

      rb = files.find { |n| n.match?(/\A#{pattern}\.rb\z/) }
      raise NotFound, "component /#{pattern}/ in runtime #{runtime_ver}" unless rb

      raw(RUNTIME_REPO, "configs/components/#{rb}", runtime_ver)[/pkg\.version\s+['"]([^'"]+)['"]/, 1]
    end

    def json_at(repo, path, ref)
      JSON.parse(raw(repo, path, ref))
    end

    def raw(repo, path, ref)
      api_get("/repos/#{repo}/contents/#{path}?ref=#{ref}", accept: 'application/vnd.github.raw')
    end

    def list_dir(repo, path, ref)
      body = api_get("/repos/#{repo}/contents/#{path}?ref=#{ref}", accept: 'application/vnd.github+json')
      JSON.parse(body).map { |entry| entry['name'] }
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

  # openvox-agent: bundled OpenFact plus Ruby/OpenSSL/curl from the agent runtime.
  #
  # Only components actually bundled by the agent runtime project (agent-runtime-8.x)
  # are reported. r10k is intentionally absent: its pin exists in puppet-runtime, but
  # it is bundled by openbolt-runtime, not the agent, so it does not ship in
  # openvox-agent (see OpenboltReleaseTable).
  class AgentReleaseTable < ReleaseTable
    REPO = 'OpenVoxProject/openvox'

    def repo
      REPO
    end

    def row_for(tag, cache)
      openfact = json_at(REPO, 'packaging/configs/components/openfact.json', tag)['ref'].delete_prefix('refs/tags/')
      runtime = json_at(REPO, 'packaging/configs/components/puppet-runtime.json', tag)['version']
      rt = (cache[runtime] ||= runtime_versions(runtime))
      { 'release' => tag, 'openfact' => openfact, 'ruby' => rt[:ruby], 'openssl' => rt[:openssl], 'curl' => rt[:curl] }
    end

    private

    def runtime_versions(runtime_ver)
      files = runtime_files(runtime_ver)
      {
        ruby: component_version('ruby-\d+\.\d+', runtime_ver, files),
        openssl: component_version('openssl-\d+\.\d+', runtime_ver, files),
        curl: component_version('curl', runtime_ver, files),
      }
    end
  end

  # openvox-server: bundled JRuby, resolved through the server's pinned
  # jruby-utils -> jruby-deps "9.4.12.1-3" (the trailing "-N" packaging suffix is
  # stripped). Java is a supported requirement, not a pin, so it is hand-maintained
  # on the docs page rather than resolved here.
  class ServerReleaseTable < ReleaseTable
    SERVER_REPO = 'OpenVoxProject/openvox-server'
    JRUBY_UTILS_REPO = 'OpenVoxProject/jruby-utils'

    def repo
      SERVER_REPO
    end

    def row_for(tag, cache)
      jruby_utils = pin_in_project_clj(SERVER_REPO, tag, 'jruby-utils')
      { 'release' => tag, 'jruby' => (cache[jruby_utils] ||= jruby_from_utils(jruby_utils)) }
    end

    private

    def jruby_from_utils(jruby_utils_ver)
      deps = pin_in_project_clj(JRUBY_UTILS_REPO, jruby_utils_ver, 'jruby-deps')
      deps.sub(/-\d+\z/, '')
    end

    # Version of an org.openvoxproject/<name> dependency pinned in a repo's project.clj.
    def pin_in_project_clj(repo, ref, name)
      clj = raw(repo, 'project.clj', ref)
      version = clj[%r{org\.openvoxproject/#{Regexp.escape(name)}\s+"([^"]+)"}, 1]
      raise NotFound, "#{name} pin in #{repo}@#{ref}" unless version

      version
    end
  end

  # OpenVoxDB ships on its own independent version line; the table is just its
  # stable release tags. PostgreSQL is a supported requirement (the openvoxdb
  # module only declares a postgresql dependency range, not a bundled version),
  # so it is hand-maintained on the docs page.
  class OpenvoxdbReleaseTable < ReleaseTable
    def repo
      'OpenVoxProject/openvoxdb'
    end

    def row_for(tag, _cache)
      { 'release' => tag }
    end
  end

  # OpenBolt ships on its own 5.x line, independent of the OpenVox major, and
  # bundles its own runtime (Ruby/OpenSSL plus r10k). r10k is bundled here, not by
  # the agent, which is why it appears on the OpenBolt table. OpenBolt also bundles
  # OpenVox itself (for `bolt apply`); its gemspec declares the requirement as a
  # range (e.g. "~> 8.0") and the exact version is resolved at build time, so the
  # table shows the declared requirement rather than a resolved version.
  class OpenboltReleaseTable < ReleaseTable
    REPO = 'OpenVoxProject/openbolt'

    def repo
      REPO
    end

    def row_for(tag, cache)
      runtime = json_at(REPO, 'packaging/configs/components/puppet-runtime.json', tag)['version']
      rt = (cache[runtime] ||= runtime_versions(runtime))
      {
        'release' => tag, 'openvox' => openvox_requirement(tag),
        'ruby' => rt[:ruby], 'openssl' => rt[:openssl], 'r10k' => rt[:r10k],
      }
    end

    private

    # "openvox" is a dependency requirement (e.g. "~> 8.0"), not a resolved version.
    def freeform_fields
      %w[openvox]
    end

    # OpenBolt's bundled-OpenVox requirement, from its gemspec.
    def openvox_requirement(tag)
      gemspec = raw(REPO, 'openbolt.gemspec', tag)
      req = gemspec[/add_dependency\s+["']openvox["']\s*,\s*["']([^"']+)["']/, 1]
      raise NotFound, "openvox dependency in openbolt.gemspec@#{tag}" unless req

      req
    end

    def runtime_versions(runtime_ver)
      files = runtime_files(runtime_ver)
      {
        ruby: component_version('ruby-\d+\.\d+', runtime_ver, files),
        openssl: component_version('openssl-\d+\.\d+', runtime_ver, files),
        r10k: component_version('rubygem-r10k', runtime_ver, files),
      }
    end
  end
end
