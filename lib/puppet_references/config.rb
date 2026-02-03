require 'yaml'
module PuppetReferences
  class Config
    def self.read
      YAML.load_file(File.join(File.dirname(__FILE__), 'config.yaml'))
    end
  end
end
