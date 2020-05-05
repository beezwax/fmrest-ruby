require "bundler/setup"

require "spyke"
require "fmrest"
require "fmrest/spyke"
require "pry-byebug"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset fixture models' connections
  config.after(:all) do
    if defined?(FixtureBase)
      [FixtureBase, *FixtureBase.descendants].each do |klass|
        klass.instance_variable_set(:@fmrest_connection, nil)
      end
    end
  end
end

# Require support files
Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require f }
