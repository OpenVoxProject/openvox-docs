# frozen_string_literal: true

require 'json'
require 'yaml'
require 'net/http'
require 'uri'

module PuppetReferences
  # Generates the openvox-agent "release contents" data from authoritative,
  # structured component pins, so the table is never hand-maintained.
  #
  # For each stable OpenVox release in the series, versions are resolved by
  # reading pinned config across two repos:
  #
  #   openvox@<tag>:packaging/configs/components/openfact.json       -> .ref      (OpenFact)
  #   openvox@<tag>:packaging/configs/components/puppet-runtime.json -> .version  (runtime)
  #   puppet-runtime@<runtime>:configs/components/ruby-*.{json,rb}    -> Ruby
  #   puppet-runtime@<runtime>:configs/components/openssl-*.{json,rb} -> OpenSSL
  #   puppet-runtime@<runtime>:configs/components/curl.{json,rb}      -> curl
  #   puppet-runtime@<runtime>:configs/components/rubygem-r10k.rb     -> r10k
  #
  # Recent components pin the version in a <name>.json (.version); older ones use
  # the vanagon <name>.rb DSL (pkg.version '...'). Both are handled.
  #
  # Authenticates with ENV GITHUB_TOKEN/GH_TOKEN, falling back to `gh auth token`
  # for local runs. Releases whose component layout can't be resolved (e.g. very
  # old tags that predate these paths) are skipped with a warning; transient API
  # failures raise so a bad run never overwrites the committed data file.
  module AgentReleaseTable
    OPENVOX_REPO = 'OpenVoxProject/openvox'
    RUNTIME_REPO = 'OpenVoxProject/puppet-runtime'
    API_ROOT = 'https://api.github.com'
    USER_AGENT = 'openvox-docs-agent-release-table'

    class NotFound < StandardError; end

    # A resolved component value must look like a dotted version. This screens out
    # boundary releases that pin a component by git SHA or whose layout yields a
    # blank, so the table only ever shows fully-resolved rows.
    VERSION_RE = /\A\d+(?:\.\d+)+\z/

    module_function

    # Resolve and write the data file consumed by the docs page. Returns the rows.
    def write_data_file(series:, min_version:, path:)
      data = rows(series: series, min_version: min_version)
      raise 'resolved no releases; refusing to overwrite data file' if data.empty?

      File.write(path, data.to_yaml)
      data
    end

    def rows(series:, min_version:)
      runtime_cache = {}
      release_tags(series: series, min_version: min_version).filter_map do |tag|
        row_for(tag, runtime_cache)
      rescue NotFound => e
        warn "skipping #{tag}: missing #{e.message}"
        nil
      end
    end

    def row_for(tag, runtime_cache)
      openfact = strip_ref(json_at(OPENVOX_REPO, 'packaging/configs/components/openfact.json', tag)['ref'])
      runtime = json_at(OPENVOX_REPO, 'packaging/configs/components/puppet-runtime.json', tag)['version']
      rt = runtime_versions(runtime, runtime_cache)
      row = {
        'release' => tag, 'openfact' => openfact,
        'ruby' => rt[:ruby], 'openssl' => rt[:openssl],
        'curl' => rt[:curl], 'r10k' => rt[:r10k],
      }
      row.each do |field, value|
        next if field == 'release' || value.to_s.match?(VERSION_RE)

        raise NotFound, "clean #{field} version (got #{value.inspect})"
      end
      row
    end

    # Stable release tags for the series (e.g. "8.") at or above min_version,
    # newest first.
    def release_tags(series:, min_version:)
      floor = Gem::Version.new(min_version)
      # Only the first page (100 newest releases) is read. Safe while min_version
      # stays near the newest releases; revisit with pagination if the series ever
      # has more than 100 releases above the floor.
      body = api_get("/repos/#{OPENVOX_REPO}/releases?per_page=100", accept: 'application/vnd.github+json')
      JSON.parse(body)
          .reject { |r| r['prerelease'] || r['draft'] }
          .map { |r| r['tag_name'] }
          .select { |t| t.start_with?(series) && Gem::Version.correct?(t) && Gem::Version.new(t) >= floor }
          .sort_by { |t| Gem::Version.new(t) }
          .reverse
    end

    # Ruby, OpenSSL, curl, and r10k for a given puppet-runtime version.
    def runtime_versions(runtime_ver, cache)
      cache[runtime_ver] ||= begin
        files = list_dir(RUNTIME_REPO, 'configs/components', runtime_ver)
        {
          ruby: component_version('ruby-\d+\.\d+', runtime_ver, files),
          openssl: component_version('openssl-\d+\.\d+', runtime_ver, files),
          curl: component_version('curl', runtime_ver, files),
          r10k: component_version('rubygem-r10k', runtime_ver, files),
        }
      end
    end

    # Component version from <name>.json (.version) or the vanagon <name>.rb DSL.
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

    def strip_ref(ref)
      ref.delete_prefix('refs/tags/')
    end

    private_class_method :row_for, :release_tags, :runtime_versions, :component_version,
                         :json_at, :raw, :list_dir, :api_get, :token, :strip_ref
  end
end
