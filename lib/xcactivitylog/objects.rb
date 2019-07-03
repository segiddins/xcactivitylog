# frozen_string_literal: true

module XCActivityLog
  class SerializedObject
    Attribute = Struct.new(:name, :type, :first_version, :first_version_without)
    def self.attribute(name, type, first_version = 0, first_version_without = 99_999)
      attr_reader name
      alias_method "#{name}?", name if type == :boolean
      if type == :time
        define_method(:"#{name}_usec") do
          time = send(name)
          time.to_i * 1_000_000 + time.usec
        end
      end
      attributes << Attribute.new(name, type, first_version, first_version_without).freeze
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
    class Severity
      protected

      attr_reader :severity

      public

      def initialize(severity)
        @severity = severity
        freeze
      end

      SUCCESS = new(0)
      WARNING = new(1)
      ERROR = new(2)
      TEST_FAILURE = new(3)

      def to_s
        case severity
        when 0
          'Success'
        when 1
          'Warning'
        when 2
          'Error'
        when 3
          'Test Failure'
        else
          "Unknown (#{severity})"
        end
      end

      include Comparable

      def <=>(other)
        severity <=> other.severity
      end
    end

    TargetInfo = Struct.new(:name, :configuration, :workspace, keyword_init: true)

    include Enumerable
    def each(&blk)
      return enum_for(__method__) unless block_given?

      yield self
      subsections&.each { |s| s.each(&blk) }
    end

    def each_with_parent(parent: nil, &blk)
      return enum_for(__method__) unless block_given?

      yield self, parent
      subsections&.each { |s| s.each_with_parent(parent: self, &blk) }
    end

    def duration_usec
      time_stopped_recording_usec - time_started_recording_usec
    end

    def target_info(parent: nil)
      parent&.target_info ||
        (title =~ /=== BUILD TARGET (.+?) OF PROJECT (.+?) WITH CONFIGURATION (.+?) ===/ &&
          TargetInfo.new(name: Regexp.last_match(1), configuration: Regexp.last_match(3), workspace: Regexp.last_match(2)))
    end

    def each_trace_event
      thread_id_map_by_section_type = Hash.new { |h, k| h[k] = [] }
      each_with_parent.sort_by { |s, _| s.time_started_recording }.each do |section, parent|
        thread_id_map = thread_id_map_by_section_type[section.section_type]
        best_thread, thread_id = thread_id_map.each_with_index.select do |thread, _tid|
          section.time_started_recording > thread.last.time_stopped_recording
        end.min_by do |thread, _tid|
          (section.time_started_recording - thread.last.time_stopped_recording) +
            (thread.last.time_stopped_recording - thread_id_map.map(&:last).map(&:time_stopped_recording).min)
        end
        unless thread_id
          thread_id = thread_id_map.size
          best_thread = []
          thread_id_map << best_thread
        end
        best_thread << section

        yield(section: section, parent: parent, thread_id: thread_id)
      end
    end

    def write_chrome_trace_file(section_type:, to:)
      to << '{"traceEvents":[' << "\n"
      written_comma = false
      each_trace_event do |section:, parent:, thread_id:|
        case section.section_type
        when section_type
          if written_comma
            to << ",\n"
          else
            written_comma = true
          end
          require 'json'
          to << JSON.generate(
            pid: section.section_type.to_s,
            tid: thread_id,
            ts: section.time_started_recording_usec,
            ph: 'X',
            name: section.title,
            dur: section.duration_usec,
            args: {
              subtitle: section.subtitle,
              target: section.target_info(parent: parent).to_h,
              severity: section.severity
            }
          )
        end
      end

      to << "\n]}"

      to
    end

    def severity
      severity = (messages || []).reduce(Severity::SUCCESS) { |a, e| [a, Severity.new(e.severity)].max }
      (subsections || []).reduce(severity) { |a, e| [a, e.severity].max }
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
    attribute :xcbuild_signature, :string, 8
    attribute :collect_metrics, :boolean, 9, 10
    attributes.freeze
  end
  class IDECommandLineBuildLog < IDEActivityLogSection
    attributes.freeze
  end
  class IDEActivityLogUnitTestSection < IDEActivityLogSection
    attribute :tests_passes, :string
    attribute :duration, :string
    attribute :summary, :string
    attribute :suite_name, :string
    attribute :test_name, :string
    attribute :performance_test_output, :string
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
    attribute :location, :document_location
    attribute :category_identifier, :string
    attribute :secondary_locations, :object_list
    attribute :additional_description, :string
    attributes.freeze
  end
  class IDEClangDiagnosticActivityLogMessage < IDEActivityLogMessage
    attributes.freeze
  end
  class IDEActivityLogAnalyzerResultMessage < IDEActivityLogMessage
    attribute :result_type, :string
    attribute :key_event_index, :int
    attributes.freeze
  end
  class IDEActivityLogAnalyzerStepMessage < IDEActivityLogMessage
    attribute :parent_index, :int
    attributes.freeze
  end
  class IDEActivityLogAnalyzerEventStepMessage < IDEActivityLogAnalyzerStepMessage
    attribute :result_type, :string
    attribute :key_event_index, :int
    attributes.freeze
  end
  class IDEActivityLogAnalyzerControlFlowStepMessage < IDEActivityLogAnalyzerStepMessage
    attribute :end_location, :document_location
    attribute :edges, :object_list
    attributes.freeze
  end
  class IDEActivityLogAnalyzerWarningMessage < IDEActivityLogMessage
    attributes.freeze
  end

  class IDEActivityLogAnalyzerControlFlowStepEdge < SerializedObject
    attribute :start_location, :document_location
    attribute :end_location, :document_location
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
    attribute :location_encoding, :int, 7
    attributes.freeze
  end
end
