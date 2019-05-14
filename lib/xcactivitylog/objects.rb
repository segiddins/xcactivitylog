# frozen_string_literal: true

module XCActivityLog
  class SerializedObject
    Attribute = Struct.new(:name, :type, :first_version, :last_version)
    def self.attribute(name, type, first_version = 0, last_version = 99_999)
      attr_reader name
      alias_method "#{name}?", name if type == :boolean
      if type == :time
        define_method(:"#{name}_usec") do
          time = send(name)
          time.to_i * 1_000_000 + time.usec
        end
      end
      attributes << Attribute.new(name, type, first_version, last_version).freeze
    end

    def self.attributes
      @attributes ||= begin
        SerializedObject == self ? [].freeze : superclass.attributes.dup
      end
    end

    def hash
      self.class.attributes.reduce(0x747) do |hash, attr|
        hash ^ send(attr.name).hash
      end
    end

    def ==(other)
      self.class.attributes.reduce(self.class == other.class) do |eq, attr|
        eq && (send(attr.name) == other.send(attr.name))
      end
    end

    def eql?(other)
      self.class.attributes.reduce(self.class == other.class) do |eq, attr|
        eq && send(attr.name).eql?(other.send(attr.name))
      end
    end
  end

  class NSRange < SerializedObject
    attribute :location, :int
    attribute :length, :int
    attributes.freeze
  end

  class IDEActivityLogSection < SerializedObject
    include Enumerable
    def each(&blk)
      return enum_for(__method__) unless block_given?

      yield self
      subsections&.each { |s| s.each(&blk) }
    end

    def duration_usec
      time_stopped_recording_usec - time_started_recording_usec
    end
    attribute :section_type, :int
    attribute :domain_type, :string
    attribute :title, :string
    attribute :signature, :string
    attribute :time_started_recording, :time
    attribute :time_stopped_recording, :time
    attribute :subsections, :object_list
    attribute :text, :string
    attribute :messages, :object_list
    attribute :cancelled, :boolean
    attribute :quiet, :boolean
    attribute :fetched_from_cache, :boolean
    attribute :subtitle, :string
    attribute :location, :document_location
    attribute :command_detail_description, :string
    attribute :unique_identifier, :string
    attribute :localized_result_string, :string
    attribute :xcbuild_signature, :string
    attribute :collect_metrics, :boolean, 9
    attributes.freeze
  end
  class IDECommandLineBuildLog < IDEActivityLogSection
    attributes.freeze
  end

  class IDEActivityLogMessage < SerializedObject
    include Enumerable
    def each(&blk)
      return enum_for(__method__) unless block_given?

      yield self
      submessages&.each { |s| s.each(&blk) }
    end
    attribute :title, :string
    attribute :short_title, :string
    attribute :time_emitted, :int
    attribute :range_in_section_text, :nsrange
    attribute :submessages, :object_list
    attribute :severity, :int
    attribute :type, :string
    attribute :location, :object
    attribute :category_identifier, :string
    attribute :secondary_locations, :object_list
    attribute :additional_description, :string
    attributes.freeze
  end
  class IDEClangDiagnosticActivityLogMessage < IDEActivityLogMessage
    attributes.freeze
  end

  class DVTDocumentLocation < SerializedObject
    attribute :document_url_string, :string
    attribute :timestamp, :double
    attributes.freeze

    def document_url
      URI::File.parse(document_url_string)
    end
  end
  class DVTTextDocumentLocation < DVTDocumentLocation
    attribute :starting_line_number, :int
    attribute :starting_column_number, :int
    attribute :ending_line_number, :int
    attribute :ending_column_number, :int
    attribute :character_range, :nsrange
    attribute :location_encoding, :int
    attributes.freeze
  end
end
