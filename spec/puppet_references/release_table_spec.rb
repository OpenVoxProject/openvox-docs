# frozen_string_literal: true

require 'json'
require 'puppet_references/release_tables'

# ReleaseTable#api_get is the only network call, so these specs stub it on the
# object under test to stay offline.
# rubocop:disable-next RSpec/SubjectStub
RSpec.describe PuppetReferences::ReleaseTable do
  subject(:table) { PuppetReferences::ServerReleaseTable.new }

  let(:pages_read) { [] }

  before do
    allow(table).to receive(:api_get) do |path, **|
      page = path[/[?&]page=(\d+)\z/, 1].to_i
      pages_read << page
      tags.drop((page - 1) * 100).first(100)
          .map { |tag| { 'tag_name' => tag, 'prerelease' => tag.include?('-'), 'draft' => false } }.to_json
    end
  end

  describe '#stable_releases' do
    context 'with more than one page of releases' do
      let(:tags) { (1..250).map { |n| "8.0.#{n}" }.reverse }

      it 'reads every page' do
        expect(table.send(:stable_releases, series: '8.').size).to eq(250)
        expect(pages_read).to eq([1, 2, 3])
      end
    end

    context 'with exactly one full page of releases' do
      let(:tags) { (1..100).map { |n| "8.0.#{n}" }.reverse }

      it 'stops at the first empty page' do
        table.send(:stable_releases, series: '8.')
        expect(pages_read).to eq([1, 2])
      end
    end
  end

  describe '#release_tags' do
    let(:tags) { %w[9.1.1 8.17.1 9.1.0 9.0.0-rc1 9.0.1 9.0.0-beta1] }

    it 'returns the stable tags in the series at or above the floor, newest first' do
      expect(table.send(:release_tags, series: '9.', min_version: '9.0.1')).to eq(%w[9.1.1 9.1.0 9.0.1])
    end
  end
end
