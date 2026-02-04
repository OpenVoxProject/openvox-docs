source 'https://rubygems.org/'
gemspec name: 'puppet_docs'

gem 'git', '~> 4.0'
gem 'json', '~> 2.5'
gem 'rack', '>= 2.2.14'
gem 'rake', '~> 13.0', '>= 13.0.1'
gem 'versionomy', '~> 0.5.0'

group(:build_site) do
  gem 'jekyll', '~> 4.1'
  gem 'kramdown', '~> 2.3'
  gem 'listen', '~> 3.10.0' # Preserve ability to run on Ruby 2.0, since listen 3.1 requires Ruby ~> 2.2.
  gem 'vlad', '~> 2.7'
  gem 'vlad-git', '~> 2.1'
end

group(:generate_references) do
  gem 'nokogiri', '>= 1.18.9'
  gem 'openvox', '~> 8'
  gem 'openvox-strings'
  gem 'pandoc-ruby'
  gem 'pragmatic_segmenter', '~> 0.3'
  gem 'punkt-segmenter', '~> 0.9'
  gem 'rdoc', '~> 7.1'
  gem 'rgen', '~> 0.8'
  gem 'yard', '~> 0.9'
end

group(:unknown) do
  gem 'activerecord', '>= 7.1.5.2'
  gem 'maruku', '~> 0.7'
end

group(:development) do
  gem 'rubocop-rake', require: false
  gem 'voxpupuli-rubocop', '~> 5.1.0'
end

# group(:debug) do
#   gem 'byebug'
# end
