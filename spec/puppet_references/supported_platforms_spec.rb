# frozen_string_literal: true

require 'json'
require 'puppet_references/supported_platforms'

# The platforms.json text is injected as `source` and the package-server
# listings through `fetcher`, so these specs never touch the network.
RSpec.describe PuppetReferences::SupportedPlatforms do
  subject(:generator) { described_class.new(source: platforms.to_json, fetcher: fetcher) }

  let(:platforms) do
    {
      'main' => {
        'vanagon' => %w[el-9-x86_64 el-9-aarch64 redhatfips-9-x86_64 fedora-43-x86_64 debian-12-amd64 macos-all-arm64],
        'ezbake-rpm' => %w[el-9 fedora-43],
        'ezbake-fips-rpm' => %w[redhatfips-9],
      },
      '8.x' => {
        'vanagon' => %w[el-7-x86_64 el-9-x86_64 fedora-42-x86_64 debian-12-amd64 ubuntu-22.04-amd64],
        'ezbake-deb' => %w[ubuntu-22.04 debian-12],
        'ezbake-rpm' => %w[el-9 fedora-42],
      },
    }
  end

  let(:listings) do
    {
      described_class::YUM_URL => autoindex(%w[
                                              openvox7/ openvox8/ openvox9/
                                              openvox7-release-fedora-36.noarch.rpm
                                              openvox8-release-el-7.noarch.rpm openvox8-release-el-9.noarch.rpm
                                              openvox8-release-fedora-36.noarch.rpm openvox8-release-fedora-42.noarch.rpm
                                              openvox8-release-redhatfips-9.noarch.rpm
                                              openvox9-release-el-9.noarch.rpm openvox9-release-fedora-43.noarch.rpm openvox9-release-redhatfips-9.noarch.rpm
                                              tools-release-el-9.noarch.rpm
                                            ]),
      described_class::APT_URL => autoindex(%w[
                                              openvox8-release-debian10.deb openvox8-release-debian12.deb openvox8-release-ubuntu18.04.deb
                                              openvox8-release-ubuntu22.04.deb openvox9-release-debian12.deb openvox9-release-keyring.gpg
                                            ]),
      "#{described_class::YUM_URL}openvox8/fedora/36/x86_64/" => autoindex(%w[
                                                                             openvox-agent-8.19.1-1.fc36.x86_64.rpm openvox-agent-8.19.2-1.fc36.x86_64.rpm openvox-agent-8.9.0-1.fc36.x86_64.rpm
                                                                           ]),
      "#{described_class::APT_URL}dists/debian10/openvox8/binary-amd64/Packages" => packages('openvox-agent' => %w[8.19.2-1+debian10 8.19.1-1+debian10], 'openvox-server' => %w[8.11.0-1+debian10]),
      # No ubuntu18.04 Packages index: that lookup fails.
    }
  end

  let(:fetcher) do
    lambda do |url|
      listings.fetch(url) { raise described_class::FetchError, "fetching #{url} failed: 404" }
    end
  end

  def autoindex(names)
    names.map { |n| %(<a href="#{n}">#{n}</a>) }.join("\n")
  end

  def packages(versions_by_package)
    versions_by_package.flat_map do |package, versions|
      versions.map { |v| "Package: #{package}\nVersion: #{v}\nArchitecture: amd64" }
    end.join("\n\n")
  end

  describe '#series_data' do
    let(:data) { generator.series_data }

    it 'emits a platforms list and a legacy list per series' do
      expect(data.keys).to eq(%w[main 8.x])
      expect(data.values).to all(include('platforms', 'legacy'))
    end

    it 'collapses the build groups into one row per operating system' do
      expect(data['main']['platforms'].map { |r| r['os'] }).to eq(['Enterprise Linux 9', 'Fedora 43', 'Debian 12', 'macOS'])
      expect(data['main']['platforms'].first).to include('agent_bolt' => %w[x86-64 Arm64], 'server_db' => true, 'fips' => true)
    end

    it 'lists the published platforms that are no longer in platforms.json, with the last agent version' do
      expect(data['8.x']['legacy']).to eq([
                                            { 'os' => 'Fedora 36', 'family' => 'fedora', 'last_version' => '8.19.2' },
                                            { 'os' => 'Debian 10', 'family' => 'debian', 'last_version' => '8.19.2' },
                                            { 'os' => 'Ubuntu 18.04', 'family' => 'ubuntu', 'last_version' => nil },
                                          ])
    end

    it 'treats the newest published major as the main series while it has no own key' do
      expect(data['main']['legacy']).to eq([])
    end

    it 'folds FIPS release packages into the Enterprise Linux row rather than listing them as legacy' do
      expect(data['8.x']['legacy'].map { |r| r['os'] }).not_to include(a_string_starting_with('Enterprise Linux'))
    end

    context 'when the major has its own series key' do
      let(:platforms) { super().merge('9.x' => super()['main'], 'main' => { 'vanagon' => %w[el-10-x86_64] }) }

      it 'attaches the published packages to that key and leaves main without legacy rows' do
        expect(data['9.x']['legacy']).to eq([])
        expect(data['main']['legacy']).to eq([])
      end
    end

    context 'when a platform directory cannot be read' do
      it 'warns and leaves the last version empty' do
        expect { data }.to output(/no last version for openvox8 ubuntu 18.04/).to_stderr
      end
    end
  end

  describe '#http_get' do
    subject(:generator) { described_class.new }

    [Net::ReadTimeout.new, SocketError.new('getaddrinfo'), OpenSSL::SSL::SSLError.new('handshake'), Errno::ECONNREFUSED.new].each do |error|
      it "wraps #{error.class} in FetchError so per-platform lookups can skip it" do
        allow(Net::HTTP).to receive(:start).and_raise(error)
        expect { generator.send(:http_get, 'https://example.invalid/') }
          .to raise_error(described_class::FetchError, /example\.invalid.*#{error.class}/)
      end
    end
  end
end
