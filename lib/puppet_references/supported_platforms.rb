# frozen_string_literal: true

require 'json'
require 'yaml'
require 'fileutils'
require 'net/http'
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
  class SupportedPlatforms
    SOURCE_URL = 'https://raw.githubusercontent.com/OpenVoxProject/shared-actions/main/platforms.json'
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

    # Resolve and write the data file consumed by the docs page. Returns the data.
    def self.write_data_file(path:, source: nil)
      data = new(source: source).series_rows
      raise 'resolved no platforms; refusing to overwrite data file' if data.empty?

      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, data.to_yaml)
      data
    end

    def initialize(source: nil)
      @source = source
    end

    # { series => [row, ...] } for every series in platforms.json.
    def series_rows
      platforms.transform_values { |groups| rows_for_series(groups) }
    end

    private

    def rows_for_series(groups)
      rows = {} # group-key => row hash

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

      finalize(rows.values)
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

      unless FAMILY_LABEL.key?(os)
        warn "supported_platforms: unknown OS family in #{platform.inspect}; skipping"
        return [nil, nil, nil]
      end

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
      @platforms ||= JSON.parse(@source || fetch)
    end

    def fetch
      uri = URI(SOURCE_URL)
      req = Net::HTTP::Get.new(uri)
      req['User-Agent'] = USER_AGENT
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
      return res.body if res.is_a?(Net::HTTPSuccess)

      raise "fetching #{SOURCE_URL} failed: #{res.code} #{res.body.to_s[0, 200]}"
    end
  end
end
