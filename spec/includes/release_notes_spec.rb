# frozen_string_literal: true

require 'fileutils'
require 'jekyll'
require 'nokogiri'
require 'tmpdir'
require 'yaml'
require_relative '../../_plugins/release_highlights'

# Renders _includes/release_notes.html through Liquid and kramdown in a one-page
# Jekyll site, with the site's own kramdown settings and the highlights plugin.
# The committed data files are empty until the next release, so the site build
# in CI would not otherwise render a generated entry.
# rubocop:disable-next RSpec/DescribeClass
RSpec.describe '_includes/release_notes.html' do
  let(:root) { File.expand_path('../..', __dir__) }
  let(:source) { Dir.mktmpdir }
  let(:entries) do
    [
      { 'version' => '9.2.0', 'date' => '2026-12-03', 'type' => 'feature',
        'url' => 'https://github.com/OpenVoxProject/openvox-server/releases/tag/9.2.0', },
      { 'version' => '9.1.2', 'date' => '2026-11-12', 'type' => 'bug-fix', 'previous' => '9.1.1',
        'url' => 'https://github.com/OpenVoxProject/openvox-server/releases/tag/9.1.2',
        'components' => [{ 'name' => 'asm', 'from' => '9.11', 'to' => '9.11.1' }, { 'name' => 'joni', 'to' => '2.2.8' }], },
    ]
  end
  let(:page) do
    build_site
    Nokogiri::HTML(File.read(File.join(source, '_site', 'release_notes.html')))
  end

  def write(path, content)
    FileUtils.mkdir_p(File.dirname(File.join(source, path)))
    File.write(File.join(source, path), content)
  end

  def build_site
    FileUtils.cp_r(File.join(root, '_includes', 'release_notes.html'), File.join(source, '_includes', 'release_notes.html'))
    write('_data/release_notes/openvox-server_9x.yml', entries.to_yaml)
    write('release_notes.md', "---\nnav: openvox-server_9x\n---\n\nIntro.\n\n" \
                              "{% include release_notes.html product=\"OpenVox Server\" %}\n\n## OpenVox Server 9.1.1\n\nHand-written.\n")
    site_config = YAML.load_file(File.join(root, '_config.yml')).slice('markdown', 'kramdown', 'timezone')
    # Jekyll defaults `destination` to ./_site, which would overwrite the real build.
    config = site_config.merge('source' => source, 'destination' => File.join(source, '_site'), 'quiet' => true)
    Jekyll::Site.new(Jekyll.configuration(config)).process
  end

  before do
    FileUtils.mkdir_p(File.join(source, '_includes'))
    write('_release_highlights/openvox-server_9x/9.1.2.md', "---\ntype: security\n---\n\n- A highlighted fix.\n")
  end

  after { FileUtils.remove_entry(source) }

  it 'renders generated entries, newest first, above the hand-written ones, with the usual anchors' do
    expect(page.css('h2').map { |h| [h['id'], h.text] }).to eq(
      [['openvox-server-920', 'OpenVox Server 9.2.0'], ['openvox-server-912', 'OpenVox Server 9.1.2'],
       ['openvox-server-911', 'OpenVox Server 9.1.1'],],
    )
  end

  it 'renders the date, the release type, and the GitHub link' do
    paragraphs = page.css('p').map(&:text)
    expect(paragraphs).to include('Released December 3, 2026.', 'This is a feature release of OpenVox Server.')
    expect(page.at_css('a[href$="/releases/tag/9.2.0"]').text).to eq('project’s GitHub release page')
  end

  it 'renders the highlights and their release type' do
    expect(page.css('p').map(&:text)).to include('This is a security release of OpenVox Server.')
    expect(page.css('li').map(&:text)).to eq(['A highlighted fix.'])
  end

  it 'renders the component changes as a collapsed table for entries that have them' do
    expect(page.css('details').size).to eq(1)
    expect(page.at_css('details summary').text).to eq('Component changes since 9.1.1')
    expect(page.css('details tbody tr').map { |row| row.css('td').map(&:text) })
      .to eq([%w[asm 9.11 9.11.1], ['joni', '(new)', '2.2.8']])
  end

  context 'with no generated entries' do
    let(:entries) { [] }

    it 'leaves the page as it was' do
      expect(page.css('h2').map { |h| h['id'] }).to eq(%w[openvox-server-911])
      expect(page.css('p').map(&:text)).to eq(%w[Intro. Hand-written.])
    end
  end
end
