require 'yaml'
require 'pathname'
require 'puppet_docs/versions'

# Load the puppet-docs config file and munge some of the data in it to make it
# more usable in some awkward contexts. The Rakefile uses this class when loading
# the config, and makes sure that both Jekyll and all our rake tasks will only
# receive the munged version.

# Where's all this config data get used? See puppet-docs/source/_config.readme for a run-down.
module PuppetDocs
  class Config < Hash
    def initialize(config_file)
      super()
      merge!(YAML.load_file(config_file))

      # Normalize lock_latest: Ensure it's a hash, and ensure version numbers are strings. This makes it easier to write
      # the list in the config file, since we can skip the quoting and curly braces.
      self['lock_latest'] = {} if self['lock_latest'].class != Hash
      self['lock_latest'].each do |prod, ver|
        self['lock_latest'][prod] = ver.to_s
      end

      # Merge document info into external sources. Expected behavior is that documents override
      # standalone sources if there's a conflict.
      self['documents'].each do |base_url, data|
        self['externalsources'][base_url] = data['external_source'] if data['external_source']
      end

      # Expand the document data:
      # - add a base_url key
      # - expand the nav path
      # - sanitize version numbers into strings
      self['documents'].each do |base_url, data|
        data['base_url'] = base_url
        data['nav'] = (Pathname.new(base_url) + data['nav']).to_s
        data['version'] = data['version'].to_s
        next unless data['my_versions'].instance_of?(Hash)

        data['my_versions'].each_key do |doc|
          data['my_versions'][doc] = data['my_versions'][doc].to_s
        end
      end

      # Index the document data by mapping version numbers to base URLs.
      # Like:
      # {'pe' => {2015.3 => '/pe/2015.3', 3.8 => '/pe/3.8'}, 'puppet' => { ... } }
      self['document_version_index'] = self['documents'].each_with_object({}) do |(base_url, data), memo|
        memo[data['doc']] ||= {}
        memo[data['doc']][data['version']] = base_url
      end

      # Lists of base URLs, in descending version order, like:
      # {'pe' => ['/pe/2015.3', '/pe/2015.2', '/pe/3.8', ...], 'puppet' => [...]}
      self['document_version_order'] = self['document_version_index'].each_with_object({}) do |(doc, ver_index), memo|
        memo[doc] = PuppetDocs::Versions.sort_descending(ver_index.keys).map { |ver| ver_index[ver] }
      end

      # Add the special "latest" version to the index.
      self['document_version_index'].each do |doc, ver_index|
        latest_ver = self['lock_latest'][doc] || PuppetDocs::Versions.latest(ver_index.keys)
        ver_index['latest'] = ver_index[latest_ver]
      end

      # Expand the document data: fill all empty my_version fields.
      document_groups = self['document_version_index'].keys
      self['documents'].each_value do |data|
        data['my_versions'] ||= {}

        # Reject any non-existent versions (they'll fall back to latest):
        data['my_versions'].reject! do |group, version|
          !self['document_version_index'][group].key?(version)
        end

        # The third rule of Tautology Club: my own version is my version.
        data['my_versions'][ data['doc'] ] = data['version']
        # As for the rest of our known document groups...
        other_groups = document_groups - [data['doc']]
        # If we have an explicit version for a given group, keep it:
        unknown_groups = other_groups.reject { |group| data['my_versions'].key?(group) }

        unknown_groups.each do |group|
          # Compile a list of the target group's versions that claim this version:
          matches = self['documents'].values.map do |candidate_data|
            next unless candidate_data['doc'] == group
            next unless candidate_data['my_versions']

            candidate_data['version'] if candidate_data['my_versions'][data['doc']] == data['version']
          end.compact
          # Pick the latest version that claimed us, or default to latest
          # (the Versions.latest method returns nil for an empty array):
          best = PuppetDocs::Versions.latest(matches) || 'latest'
          data['my_versions'][group] = best
        end
      end

      # Duplicate the documents hash under a new name that doesn't conflict with Jekyll's
      # site.documents method. :( If you don't do this, you can't access the documents in templates.
      self['document_list'] = self['documents']

      # Use the defaultnav hash to set "nav" in Jekyll's frontmatter defaults. Our template passes this to
      # the {% partial %} tag to render the sidebar nav snippet.
      # We don't set these defaults directly in _config.yml because Jekyll's format for them is really unwieldy, and
      # also because nav is the only path-prefix config we use.
      self['defaults'] ||= []
      self['defaultnav'].each do |prefix, nav|
        new_default = {
          # Jekyll requires us to strip any trailing or leading slash.
          'scope' => { 'path' => prefix.sub(%r{\A/}, '').sub(%r{/\Z}, '') },
          'values' => { 'nav' => nav },
        }
        self['defaults'] << new_default
      end
    end
  end
end
