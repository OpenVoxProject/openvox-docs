require 'puppet_references'

module PuppetReferences
  module Puppet
    class TypeStrings < PuppetReferences::Puppet::Type
      def initialize(*)
        super
        @output_dir_individual = PuppetReferences::OUTPUT_DIR + 'puppet/types_strings'
        @base_filename = 'type_strings'
      end

      def get_type_json
        # 1. Get Strings JSON.
        # 2. Munge it to match the old format I threw together, which the template uses.
        # 3. Dump result to JSON.
        strings_data = PuppetReferences::Puppet::Strings.new
        File.write('references_output/puppet/raw_strings_data_output.json', strings_data)
        type_hash = strings_data['resource_types'].each_with_object({}) do |type, memo|
          memo[ type['name'] ] = {
            'description' => type['docstring']['text'],
            'features' => (type['features'] || []).each_with_object({}) do |feature, memo|
              memo[feature['name']] = feature['description']
            end,
            'providers' => strings_data['providers'].select do |provider|
              provider['type_name'] == type['name']
            end.each_with_object({}) do |provider, memo|
              description = provider['docstring']['text']
              description += "\n" if provider['commands'] || provider['confines'] || provider['defaults']
              if provider['commands']
                description += "\n* Required binaries: `#{provider['commands'].values.sort.join('`, `')}`"
              end
              if provider['confines']
                description += "\n* Confined to: `#{provider['confines'].map do |fact, val|
                  "#{fact} == #{val}"
                end.join('`, `')}`"
              end
              if provider['defaults']
                description += "\n* Default for: `#{provider['defaults'].map do |fact, val|
                  "#{fact} == #{val}"
                end.join('`, `')}`"
              end
              if provider['features']
                description += "\n* Supported features: `#{provider['features'].sort.join('`, `')}`"
              end
              memo[provider['name']] = {
                'features' => provider['features'] || [],
                'description' => description,
              }
            end,
            'attributes' => (type['parameters'] || []).each_with_object({}) do |attribute, memo|
              description = attribute['description'] || ''
              description += "\n\nDefault: `#{attribute['default']}`" if attribute['default']
              if attribute['values']
                description = description + "\n\nAllowed values:\n\n" + attribute['values'].map { |val|
                  "* `#{val}`"
                }.join("\n")
              end
              memo[attribute['name']] = {
                'description' => description,
                'kind' => 'parameter',
                'namevar' => attribute['isnamevar'] ? true : false,
                'required_features' => attribute['required_features'],
              }
            end.merge((type['properties'] || []).each_with_object({}) do |attribute, memo|
                        description = attribute['description'] || ''
                        description += "\n\nDefault: `#{attribute['default']}`" if attribute['default']
                        if attribute['values']
                          description = description + "\n\nAllowed values:\n\n" + attribute['values'].map { |val|
                            "* `#{val}`"
                          }.join("\n")
                        end
                        memo[attribute['name']] = {
                          'description' => description,
                          'kind' => 'property',
                          'namevar' => false,
                          'required_features' => attribute['required_features'],
                        }
                      end).merge((type['checks'] || []).each_with_object({}) do |attribute, memo|
                                   description = attribute['description'] || ''
                                   description += "\n\nDefault: `#{attribute['default']}`" if attribute['default']
                                   if attribute['values']
                                     description = description + "\n\nAllowed values:\n\n" + attribute['values'].map { |val|
                                       "* `#{val}`"
                                     }.join("\n")
                                   end
                                   memo[attribute['name']] = {
                                     'description' => description,
                                     'kind' => 'check',
                                     'namevar' => false,
                                     'required_features' => attribute['required_features'],
                                   }
                                 end),
          }
        end
        JSON.pretty_generate(type_hash)
      end
    end
  end
end
