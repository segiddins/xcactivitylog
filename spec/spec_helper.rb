# frozen_string_literal: true

require 'bundler/setup'
require 'xcactivitylog'
require 'util/xcactivity_log_yaml_helper'

RSpec.configure do |config|
  # Helper to sanitize the generated YAML due to different results on
  # CI vs local
  config.include XCActivityLogYAMLHelper

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
