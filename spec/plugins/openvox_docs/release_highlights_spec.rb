# frozen_string_literal: true

require 'fileutils'
require 'jekyll'
require 'tmpdir'
require_relative '../../../_plugins/release_highlights'

RSpec.describe OpenvoxDocs::ReleaseHighlights do
  let(:source) { Dir.mktmpdir }
  let(:data) { { 'release_notes' => { 'openvox-server_9x' => [{ 'version' => '9.1.2' }, { 'version' => '9.1.3' }] } } }
  let(:site) { instance_double(Jekyll::Site, source: source, data: data) }

  def highlight(version, content)
    dir = File.join(source, '_release_highlights', 'openvox-server_9x')
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "#{version}.md"), content)
  end

  before do
    allow(Jekyll.logger).to receive(:warn)
    highlight('9.1.2', "---\ntype: security\n---\n\nNotable changes in this release:\n\n- A fix.\n")
    highlight('9.1.3', "- A bullet with no front matter.\n")
  end

  after { FileUtils.remove_entry(source) }

  it 'exposes the front matter and the body of each file' do
    described_class.load(site)
    expect(data.dig('release_highlights', 'openvox-server_9x', '9.1.2'))
      .to eq('type' => 'security', 'body' => "Notable changes in this release:\n\n- A fix.")
  end

  it 'reads a file without front matter as body only' do
    described_class.load(site)
    expect(data.dig('release_highlights', 'openvox-server_9x', '9.1.3')).to eq('body' => '- A bullet with no front matter.')
  end

  it 'does not warn when every file has a generated entry' do
    described_class.load(site)
    expect(Jekyll.logger).not_to have_received(:warn)
  end

  it 'warns about a file with no generated entry' do
    highlight('9.9.9', "- A typo in the version.\n")
    described_class.load(site)
    expect(Jekyll.logger).to have_received(:warn)
      .with('Release highlights:', '_release_highlights/openvox-server_9x/9.9.9.md has no generated entry')
  end
end
