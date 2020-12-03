# frozen_string_literal: true

require 'zlib'

module XCActivityLog
  class Error < StandardError; end

  autoload :Parser, 'xcactivitylog/parser'

  def self.parse_file(path:)
    contents = File.open(path, 'rb', &:read)
    unzipped_contents = Zlib.gunzip(contents)

    Parser.new(class_deserializer: {}).parse!(unzipped_contents)
  rescue Zlib::GzipFile::Error => e
    puts "ERROR: Unable to parse xcactivity log at path #{path} - #{e.message}. Skipping."
  end
end
