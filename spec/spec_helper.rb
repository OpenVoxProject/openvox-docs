# frozen_string_literal: true

# Unit tests for the Ruby that generates site data (lib/) and the Jekyll plugins
# (_plugins/). They never call GitHub: specs stub ReleaseTable#api_get, so they
# run offline and need no token. The rendered pages are covered by the site build.
RSpec.configure do |config|
  config.disable_monkey_patching!
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.order = :random
  Kernel.srand config.seed
end
