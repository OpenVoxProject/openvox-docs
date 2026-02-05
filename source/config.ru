# frozen_string_literal: true

require 'pathname'

class DirectoryIndex
  def initialize(app)
    @app = app
  end

  def call(env)
    %w[REQUEST_METHOD REQUEST_URI PATH_INFO].each do |name|
      value = env[name]
      value << 'index.html' if value && value =~ %r{/$}
    end
    @app.call(env)
  end
end

puts '>>> Serving at http://localhost:9292'

use DirectoryIndex
run Rack::Directory.new(Pathname.new(__FILE__).parent)
