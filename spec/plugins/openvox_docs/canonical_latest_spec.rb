# frozen_string_literal: true

require 'jekyll'
require_relative '../../../_plugins/canonical_latest'

RSpec.describe OpenvoxDocs::CanonicalLatest do
  def collection(label, urls)
    docs = urls.map { |url| instance_double(Jekyll::Document, url: url, data: {}) }
    instance_double(Jekyll::Collection, label: label, docs: docs)
  end

  def canonicals(collection)
    collection.docs.map { |doc| doc.data['canonical_url'] }
  end

  def products
    {
      'openvox' => {
        'latest' => '9x',
        'versions' => [
          { 'id' => '9x', 'collection' => '_openvox_9x', 'base' => '/openvox/9.x/' },
          { 'id' => '8x', 'collection' => '_openvox_8x', 'base' => '/openvox/8.x/' },
        ],
      },
      'openbolt' => {
        'latest' => 'latest',
        'versions' => [
          { 'id' => 'latest', 'collection' => '_openbolt_latest', 'base' => '/openbolt/latest/',
            'aliases' => [{ 'collection' => '_openbolt_5x', 'base' => '/openbolt/5.x/' }], },
        ],
      },
    }
  end
  let(:numbered) { collection('openvox_9x', ['/openvox/9.x/index.html']) }
  let(:frozen) { collection('openvox_8x', ['/openvox/8.x/index.html']) }
  let(:real_latest) { collection('openbolt_latest', ['/openbolt/latest/index.html']) }
  let(:aliased) { collection('openbolt_5x', ['/openbolt/5.x/index.html']) }
  let(:site) do
    instance_double(
      Jekyll::Site,
      config: { 'url' => '' },
      data: { 'products' => products },
      collections: {
        'openvox_9x' => numbered, 'openvox_8x' => frozen,
        'openbolt_latest' => real_latest, 'openbolt_5x' => aliased,
      },
    )
  end

  before { described_class.apply(site) }

  it 'points the numbered copy of the latest version at its /latest/ twin' do
    expect(canonicals(numbered)).to eq(['https://docs.openvoxproject.org/openvox/latest/index.html'])
  end

  it 'leaves a frozen older version alone' do
    expect(canonicals(frozen)).to eq([nil])
  end

  it 'leaves a real _latest collection alone' do
    expect(canonicals(real_latest)).to eq([nil])
  end

  it 'points an alias of the latest version at its /latest/ twin' do
    expect(canonicals(aliased)).to eq(['https://docs.openvoxproject.org/openbolt/latest/index.html'])
  end
end
