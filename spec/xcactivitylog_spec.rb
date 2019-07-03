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
        chrome_trace_files = [0, 1, 2, 3].map { |i| [parsed.first.write_chrome_trace_file(section_type: i, to: +''), log + ".#{i}.trace"] }
        aggregate_failures do
          if !File.file?(yaml_path)
            satisfy("missing #{yaml_path}") { false }
          else
            expect(yaml).to eq(File.read(yaml_path))
          end
          File.write(yaml_path, yaml)

          chrome_trace_files.each do |trace_file_contents, trace_path|
            if !File.file?(trace_path)
              satisfy("missing #{trace_path}") { false }
            else
              expect(trace_file_contents).to eq(File.read(trace_path))
            end
            File.write(trace_path, trace_file_contents)
          end
        end
      end
    end
  end
end
