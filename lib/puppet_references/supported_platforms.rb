# frozen_string_literal: true

require 'json'
require 'yaml'
require 'fileutils'
require 'net/http'
require 'openssl'
require 'uri'

module PuppetReferences
  # Generates the data file rendered on the OpenVox "supported platforms" page
  # from the authoritative platforms.json in OpenVoxProject/shared-actions. That
  # file is the single list the OpenVox build system uses to decide where it
  # builds packages, so deriving the docs table from it keeps the two from
  # drifting.
  #
  # platforms.json is keyed by series ("main" = the in-development next major;
  # "8.x" = the 8.x line). Under each series, the `vanagon` group lists the
  # platforms the Ruby projects (openvox-agent, OpenBolt) build for, carrying CPU
  # arch; the `ezbake-*` groups list the platforms the JVM projects
  # (openvox-server, OpenVoxDB) build for, which are architecture-independent. We
  # collapse those into one row per operating system, tracking the agent/bolt
  # arches, whether server/db are built, and whether a FIPS build exists.
  #
  # platforms.json only says where packages are built today. A platform dropped
  # from it keeps its old packages on the package servers, so each series also
  # gets a `legacy` list: the release packages on yum.voxpupuli.org and
  # apt.voxpupuli.org for that major, minus the platforms still in
  # platforms.json, with the last openvox-agent version shipped there.
  class SupportedPlatforms
    SOURCE_URL = 'https://raw.githubusercontent.com/OpenVoxProject/shared-actions/main/platforms.json'
    YUM_URL = 'https://yum.voxpupuli.org/'
    APT_URL = 'https://apt.voxpupuli.org/'
    USER_AGENT = 'openvox-docs-supported-platforms'

    VANAGON_GROUP = 'vanagon'
    # ezbake-fips-rpm only contributes the FIPS flag; the OS itself is already
    # covered by the el/redhatfips rows, so it does not add new server/db rows.
    EZBAKE_GROUPS = %w[ezbake-deb ezbake-rpm ezbake-fips-rpm].freeze

    # Display label per OS family. `el` and `redhatfips` share the Enterprise
    # Linux label; the FIPS variant only sets the per-row fips flag.
    FAMILY_LABEL = {
      'el' => 'Enterprise Linux',
      'redhatfips' => 'Enterprise Linux',
      'amazon' => 'Amazon Linux',
      'fedora' => 'Fedora',
      'sles' => 'SLES',
      'debian' => 'Debian',
      'ubuntu' => 'Ubuntu',
      'macos' => 'macOS',
      'windows' => 'Windows',
    }.freeze

    # Row order on the rendered page, grouped by family then version ascending.
    FAMILY_ORDER = %w[el amazon fedora sles debian ubuntu macos windows].freeze

    # Families whose platform string carries no real version (the middle token is
    # a variant like "all" or "msys2", not a release), rendered as a single row.
    VERSIONLESS = %w[macos windows].freeze

    # Build-arch tokens normalized to the labels shown on the page.
    ARCH_LABEL = {
      'x86_64' => 'x86-64', 'amd64' => 'x86-64', 'x64' => 'x86-64',
      'aarch64' => 'Arm64', 'arm64' => 'Arm64',
      'armhf' => 'armhf',
    }.freeze

    # macOS reads more naturally with marketing arch names than raw CPU arches.
    MACOS_ARCH_LABEL = { 'x86_64' => 'Intel', 'arm64' => 'Apple Silicon' }.freeze

    ARCH_ORDER = ['x86-64', 'Arm64', 'armhf', 'Intel', 'Apple Silicon'].freeze

    # The release packages at the root of each package server name the major and
    # the platform: openvox8-release-fedora-36.noarch.rpm on yum,
    # openvox8-release-debian10.deb and openvox8-release-ubuntu18.04.deb on apt.
    YUM_RELEASE = /\Aopenvox(\d+)-release-([a-z]+)-([\d.]+)\.noarch\.rpm\z/
    APT_RELEASE = /\Aopenvox(\d+)-release-([a-z]+)([\d.]+)\.deb\z/
    # openvox-agent-8.19.2-1.fc36.x86_64.rpm in a yum platform directory.
    AGENT_RPM = /\Aopenvox-agent-(\d+(?:\.\d+)*)-/

    class FetchError < StandardError; end

    # Resolve and write the data file consumed by the docs page. Returns the data.
    def self.write_data_file(path:, source: nil)
      data = new(source: source).series_data
      raise 'resolved no platforms; refusing to overwrite data file' if data.empty?

      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, data.to_yaml)
      data
    end

    # `source` is the platforms.json text (fetched when nil). `fetcher` is a
    # callable taking a URL and returning the body, for the package-server
    # listings; specs inject one to stay offline.
    def initialize(source: nil, fetcher: nil)
      @source = source
      @fetcher = fetcher || method(:http_get)
    end

    # { series => { 'platforms' => [row, ...], 'legacy' => [row, ...] } } for
    # every series in platforms.json.
    def series_data
      platforms.to_h do |series, groups|
        built = collect_rows(groups)
        [series, { 'platforms' => finalize(built.values), 'legacy' => legacy_rows(series, built.keys) }]
      end
    end

    private

    # { [family, version] => row } for one series of platforms.json.
    def collect_rows(groups)
      rows = {}

      Array(groups[VANAGON_GROUP]).each do |platform|
        family, version, arch = parse(platform, arch: true)
        next unless family

        row = (rows[[family, version]] ||= new_row(family, version))
        row['fips'] = true if family_fips?(platform)
        next if arch.nil?

        (row['agent_bolt'] ||= []) << display_arch(family, arch)
      end

      EZBAKE_GROUPS.each do |group|
        fips = group.include?('fips')
        Array(groups[group]).each do |platform|
          family, version, = parse(platform, arch: false)
          next unless family

          row = (rows[[family, version]] ||= new_row(family, version))
          row['fips'] = true if fips
          row['server_db'] = true
        end
      end

      rows
    end

    # Platforms that have packages for this series on the package servers but
    # are no longer in platforms.json, with the last openvox-agent shipped.
    def legacy_rows(series, built)
      major = published.keys.find { |m| series_for_major(m) == series }
      return [] unless major

      rows = published[major].filter_map do |os, version, repo|
        family = grouping_family(os)
        next if built.include?([family, version])

        new_row(family, version).slice('os', 'family', 'version')
                                .merge('last_version' => last_agent_version(major, os, version, repo))
      end
      finalize(rows)
    end

    # { major => [[os, version, :yum|:apt], ...] } from the release packages on
    # the two package servers, limited to OS families the page knows.
    def published
      @published ||= begin
        found = Hash.new { |h, k| h[k] = [] }
        links(@fetcher.call(YUM_URL)).each do |name|
          next unless (m = YUM_RELEASE.match(name))

          found[m[1].to_i] << [m[2], m[3], :yum] if known_os?(m[2], name)
        end
        links(@fetcher.call(APT_URL)).each do |name|
          next unless (m = APT_RELEASE.match(name))

          found[m[1].to_i] << [m[2], m[3], :apt] if known_os?(m[2], name)
        end
        found.transform_values(&:uniq)
      end
    end

    # The package servers are keyed by major (openvox8/, openvox9/) while
    # platforms.json keys a line as "8.x" once it is branched and keeps the
    # newest one under "main" until then. A major with neither (openvox7) has no
    # series in the docs and is skipped.
    def series_for_major(major)
      key = "#{major}.x"
      return key if platforms.key?(key)
      return 'main' if major == published.keys.max && platforms.key?('main')

      nil
    end

    def last_agent_version(major, os, version, repo)
      versions = (repo == :apt) ? apt_agent_versions(major, os, version) : yum_agent_versions(major, os, version)
      versions.max_by { |v| Gem::Version.new(v) }
    rescue FetchError => e
      warn "supported_platforms: #{e.message}; no last version for openvox#{major} #{os} #{version}"
      nil
    end

    def yum_agent_versions(major, os, version)
      links(@fetcher.call("#{YUM_URL}openvox#{major}/#{os}/#{version}/x86_64/"))
        .filter_map { |name| AGENT_RPM.match(name)&.[](1) }
    end

    # The apt Packages index is a series of blank-line separated stanzas; the
    # version carries a packaging suffix ("8.19.2-1+debian10") we drop.
    def apt_agent_versions(major, os, version)
      body = @fetcher.call("#{APT_URL}dists/#{os}#{version}/openvox#{major}/binary-amd64/Packages")
      body.split(/\n{2,}/).filter_map do |stanza|
        next unless stanza.match?(/^Package: openvox-agent$/)

        stanza[/^Version: (\d+(?:\.\d+)*)/, 1]
      end
    end

    # href targets of an nginx autoindex listing.
    def links(html)
      html.scan(/href="([^"]+)"/).flatten
    end

    def known_os?(os, name)
      return true if FAMILY_LABEL.key?(os)

      warn "supported_platforms: unknown OS family in #{name.inspect}; skipping"
      false
    end

    # A platform string is "<os>-<version>-<arch>" (vanagon) or "<os>-<version>"
    # (ezbake). macOS/Windows carry a variant token ("all"/"msys2") in place of a
    # version. Returns [grouping-family, version-or-nil, arch-or-nil]; family is
    # nil (with a warning) for an unmapped OS so a new platform never silently
    # vanishes nor breaks the build.
    def parse(platform, arch:)
      tokens = platform.split('-')
      os = tokens.shift
      a = arch ? tokens.pop : nil

      return [nil, nil, nil] unless known_os?(os, platform)

      version = VERSIONLESS.include?(os) ? nil : tokens.join('-')
      [grouping_family(os), version, a]
    end

    # redhatfips rows fold into the matching Enterprise Linux row.
    def grouping_family(os)
      (os == 'redhatfips') ? 'el' : os
    end

    def family_fips?(platform)
      platform.start_with?('redhatfips-')
    end

    def new_row(family, version)
      label = FAMILY_LABEL.fetch(family)
      { 'os' => version.nil? ? label : "#{label} #{version}", 'family' => family,
        'version' => version, 'agent_bolt' => nil, 'server_db' => false, 'fips' => false, }
    end

    def display_arch(family, arch)
      return MACOS_ARCH_LABEL.fetch(arch, arch) if family == 'macos'

      ARCH_LABEL.fetch(arch) do
        warn "supported_platforms: unknown arch #{arch.inspect}; passing through"
        arch
      end
    end

    # Sort rows for display and tidy each one: order/uniq the arch list, and drop
    # the grouping-only `version` field from the emitted data.
    def finalize(rows)
      rows.each do |row|
        row['agent_bolt'] = row['agent_bolt'].uniq.sort_by { |a| ARCH_ORDER.index(a) || ARCH_ORDER.size } if row['agent_bolt']
      end
      rows.sort_by! { |row| [FAMILY_ORDER.index(row['family']) || FAMILY_ORDER.size, version_key(row['version'])] }
      rows.each { |row| row.delete('version') }
      rows
    end

    # Numeric-aware version sort key so "el 9" precedes "el 10".
    def version_key(version)
      return [] if version.nil?

      version.split('.').map(&:to_i)
    end

    def platforms
      @platforms ||= JSON.parse(@source || http_get(SOURCE_URL))
    end

    # Transport failures (timeouts, DNS, TLS, refused connections) are wrapped
    # in FetchError too, so a flaky per-platform lookup is skipped with a
    # warning instead of aborting the whole refresh.
    def http_get(url)
      uri = URI(url)
      req = Net::HTTP::Get.new(uri)
      req['User-Agent'] = USER_AGENT
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
      return res.body if res.is_a?(Net::HTTPSuccess)

      raise FetchError, "fetching #{url} failed: #{res.code} #{res.body.to_s[0, 200]}"
    rescue SystemCallError, SocketError, IOError, Timeout::Error, OpenSSL::SSL::SSLError, Net::ProtocolError => e
      raise FetchError, "fetching #{url} failed: #{e.class}: #{e.message}"
    end
  end
end
