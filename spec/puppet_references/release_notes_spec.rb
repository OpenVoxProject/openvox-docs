# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'tmpdir'
require 'yaml'
require 'puppet_references/release_notes'

# ReleaseTable#api_get is the only network call, so these specs stub it (and
# Kernel#warn) on the object under test to stay offline.
# rubocop:disable-next RSpec/SubjectStub
RSpec.describe PuppetReferences::ReleaseNotes do
  def release(tag, prerelease: false, draft: false)
    { 'tag_name' => tag, 'prerelease' => prerelease, 'draft' => draft,
      'published_at' => '2026-10-29T17:53:05Z',
      'html_url' => "https://github.com/OpenVoxProject/openvox-server/releases/tag/#{tag}", }
  end

  describe '#entries' do
    subject(:notes) { described_class.new(repo: 'OpenVoxProject/openvox-server', sbom_package: 'openvox-server') }

    let(:releases) do
      [release('9.2.0'), release('9.1.2'), release('9.3.0-rc1', prerelease: true), release('9.1.3', draft: true),
       release('8.17.2'), release('9.1.1'), release('9.1.0'), release('9.0.1'),]
    end
    let(:sboms) do
      {
        '9.1.0' => { 'asm' => '9.11', 'jetty-server' => '12.1.12', 'joni' => '2.2.7' },
        '9.1.1' => { 'asm' => '9.11.1', 'jetty-server' => '12.1.12', 'joni' => '2.2.7' },
        '9.1.2' => { 'asm' => '9.11.1', 'jetty-server' => '12.1.14', 'logback-core' => '1.6.6' },
        '9.2.0' => { 'asm' => '9.11.1', 'jetty-server' => '12.1.14', 'logback-core' => '1.6.6' },
      }
    end

    def versions(entries)
      entries.map { |entry| entry['version'] }
    end

    before do
      allow(notes).to receive(:warn)
      allow(notes).to receive(:api_get) do |path, **|
        case path
        when /[?&]page=(\d+)\z/
          (releases.each_slice(100).to_a[Regexp.last_match(1).to_i - 1] || []).to_json
        when %r{/sbom/openvox-server_(.+)\.cdx\.json}
          components = sboms.fetch(Regexp.last_match(1)) { raise PuppetReferences::ReleaseTable::NotFound, path }
          { 'components' => components.map { |name, version| { 'name' => name, 'version' => version } } }.to_json
        else
          raise "unexpected API call #{path}"
        end
      end
    end

    it 'lists the stable releases in the series newer than the cutoff, newest first' do
      expect(versions(notes.entries(series: '9.', after: '9.1.0'))).to eq(%w[9.2.0 9.1.2 9.1.1])
    end

    it 'keeps the series apart' do
      expect(versions(notes.entries(series: '8.', after: '8.17.1'))).to eq(%w[8.17.2])
    end

    it 'records the publication date, the release link, and a bug-fix type for a patch release' do
      expect(notes.entries(series: '9.', after: '9.1.1').last).to include(
        'version' => '9.1.2', 'date' => '2026-10-29', 'type' => 'bug-fix',
        'url' => 'https://github.com/OpenVoxProject/openvox-server/releases/tag/9.1.2'
      )
    end

    it 'calls an x.y.0 release a feature release' do
      expect(notes.entries(series: '9.', after: '9.1.2').first).to include('version' => '9.2.0', 'type' => 'feature')
    end

    it 'compares the oldest entry with the release at the cutoff' do
      expect(notes.entries(series: '9.', after: '9.1.0').last).to include(
        'version' => '9.1.1', 'previous' => '9.1.0',
        'components' => [{ 'name' => 'asm', 'from' => '9.11', 'to' => '9.11.1' }]
      )
    end

    it 'lists changed, added, and removed components by name' do
      expect(notes.entries(series: '9.', after: '9.1.1').last['components']).to eq(
        [{ 'name' => 'jetty-server', 'from' => '12.1.12', 'to' => '12.1.14' },
         { 'name' => 'joni', 'from' => '2.2.7' }, { 'name' => 'logback-core', 'to' => '1.6.6' },],
      )
    end

    it 'leaves out the table when no component changed' do
      expect(notes.entries(series: '9.', after: '9.1.2').first.keys).to eq(%w[version date url type])
    end

    it 'leaves out the table for the first stable release in a series' do
      entry = notes.entries(series: '9.', after: '9.0.0').last
      expect(entry['version']).to eq('9.0.1')
      expect(entry).not_to have_key('components')
    end

    it 'leaves out the table, and warns, when an SBOM is not published yet' do
      sboms.delete('9.1.0')
      expect(notes.entries(series: '9.', after: '9.1.0').last.keys).to eq(%w[version date url type])
      expect(notes).to have_received(:warn).with(/no component changes for openvox-server 9\.1\.1/)
    end

    context 'with more than one page of releases' do
      let(:releases) { (1..250).map { |n| release("8.0.#{n}") }.reverse }

      it 'keeps every entry' do
        expect(notes.entries(series: '8.', after: '8.0.0').size).to eq(250)
      end
    end
  end

  describe '.write_all' do
    subject(:write_all) { described_class.write_all(products: products, dir: dir) }

    let(:dir) { Dir.mktmpdir }
    let(:generator) { instance_double(described_class) }
    let(:products) do
      {
        'openvox-server' => {
          'release_notes' => { 'repo' => 'OpenVoxProject/openvox-server', 'sbom' => 'openvox-server' },
          'versions' => [
            { 'label' => '9.x', 'collection' => '_openvox-server_9x', 'release_notes_after' => '9.1.1' },
            { 'label' => '8.x', 'collection' => '_openvox-server_8x', 'release_notes_after' => '8.17.1' },
            { 'label' => '7.x', 'collection' => '_openvox-server_7x' },
          ],
        },
        'openfact' => {
          'versions' => [{ 'label' => '5.x', 'collection' => '_openfact_5x', 'release_notes_after' => '5.7.0' }],
        },
      }
    end

    before do
      allow(described_class).to receive(:new)
        .with(repo: 'OpenVoxProject/openvox-server', sbom_package: 'openvox-server').and_return(generator)
      allow(generator).to receive(:entries).with(series: '9.', after: '9.1.1').and_return([{ 'version' => '9.1.2' }])
      allow(generator).to receive(:entries).with(series: '8.', after: '8.17.1').and_raise('GitHub API 502')
      allow(described_class).to receive(:puts)
      allow(described_class).to receive(:warn)
      File.write(File.join(dir, 'openvox-server_8x.yml'), "--- committed\n")
    end

    after { FileUtils.remove_entry(dir) }

    it 'returns the pages whose refresh failed' do
      expect(write_all).to eq(%w[openvox-server_8x])
    end

    it "writes each page's entries to <nav>.yml" do
      write_all
      expect(YAML.load_file(File.join(dir, 'openvox-server_9x.yml'))).to eq([{ 'version' => '9.1.2' }])
    end

    it 'keeps the committed data file of a page whose refresh failed' do
      write_all
      expect(File.read(File.join(dir, 'openvox-server_8x.yml'))).to eq("--- committed\n")
    end

    it 'skips products and versions without release-notes settings' do
      write_all
      expect(Dir.children(dir)).to contain_exactly('openvox-server_9x.yml', 'openvox-server_8x.yml')
    end
  end

  # The same fallback, driven through real generator instances with only the
  # HTTP call stubbed: a server error anywhere in the refresh must reach
  # write_all's rescue, while a 404 for an SBOM only drops that entry's table.
  describe '.write_all when the GitHub API fails' do
    subject(:write_all) { described_class.write_all(products: products, dir: dir) }

    let(:dir) { Dir.mktmpdir }
    let(:products) do
      { 'openvox-server' => {
        'release_notes' => { 'repo' => 'OpenVoxProject/openvox-server', 'sbom' => 'openvox-server' },
        'versions' => [{ 'label' => '8.x', 'collection' => '_openvox-server_8x', 'release_notes_after' => '8.0.100' }],
      } }
    end
    let(:releases) { (1..150).map { |n| release("8.0.#{n}") }.reverse }
    let(:sboms) { { '8.0.149' => { 'jetty-server' => '12.1.12' }, '8.0.150' => { 'jetty-server' => '12.1.14' } } }
    let(:failing) { nil }

    def data_file
      File.join(dir, 'openvox-server_8x.yml')
    end

    def github(path)
      raise "GitHub API 502 for #{path}" if failing&.match?(path)

      case path
      when /[?&]page=(\d+)\z/
        (releases.each_slice(100).to_a[Regexp.last_match(1).to_i - 1] || []).to_json
      when %r{/sbom/openvox-server_(.+)\.cdx\.json}
        components = sboms.fetch(Regexp.last_match(1)) { raise PuppetReferences::ReleaseTable::NotFound, path }
        { 'components' => components.map { |name, version| { 'name' => name, 'version' => version } } }.to_json
      end
    end

    before do
      allow(described_class).to receive(:new).and_wrap_original do |new, **args|
        new.call(**args).tap do |notes|
          allow(notes).to receive(:warn)
          allow(notes).to receive(:api_get) { |path, **| github(path) }
        end
      end
      allow(described_class).to receive(:puts)
      allow(described_class).to receive(:warn)
      File.write(data_file, "--- committed\n")
    end

    after { FileUtils.remove_entry(dir) }

    it 'writes every entry, with a table only where both SBOMs are published' do
      expect(write_all).to be_empty
      entries = YAML.load_file(data_file)
      expect(entries.size).to eq(50)
      expect(entries.first).to include('version' => '8.0.150', 'previous' => '8.0.149')
      expect(entries.last).to include('version' => '8.0.101').and(satisfy { |entry| !entry.key?('components') })
    end

    context 'when a later page of releases fails' do
      let(:failing) { /[?&]page=2\z/ }

      it 'keeps the committed data file' do
        expect(write_all).to eq(%w[openvox-server_8x])
        expect(File.read(data_file)).to eq("--- committed\n")
      end
    end

    context 'when an SBOM request fails with a server error' do
      let(:failing) { %r{/sbom/openvox-server_8\.0\.149\.} }

      it 'keeps the committed data file' do
        expect(write_all).to eq(%w[openvox-server_8x])
        expect(File.read(data_file)).to eq("--- committed\n")
      end
    end
  end
end
