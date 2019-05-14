# frozen_string_literal: true

require 'xcactivitylog'
require 'yaml'

RSpec.describe XCActivityLog do
  context 'it correctly parses activity logs' do
    base_dir = pp File.join(__dir__, 'fixtures', 'xcactivitylog')
    Dir[File.join('{**,}', '*.xcactivitylog'), base: base_dir].each do |log|
      it log do
        log = File.expand_path(log, base_dir)
        parsed = XCActivityLog.parse_file(path: log)
        yaml = YAML.dump(parsed)
        yaml_path = log + '.yaml'
        aggregate_failures do
          expect(yaml).to eq(File.read(yaml_path))
          # loaded = YAML.load(File.read(yaml_path))
          # expect(parsed.first).to eq(loaded.first)
          File.write(yaml_path, yaml)
        end
      end
    end
  end
end
