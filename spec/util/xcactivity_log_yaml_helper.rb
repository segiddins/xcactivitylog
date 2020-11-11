# frozen_string_literal: true

require 'bundler/setup'
require 'yaml'

# Helper to sanitize the generated YAML due to different results on
# CI vs local
module XCActivityLogYAMLHelper
  def sanitized_yaml(parsed_log)
    sanitized = YAML.dump(parsed_log)
    sanitized.gsub!(/: $/, ':')
    sanitized.gsub!(/^ ++'$/, '\'')
    sanitized
  end
end
