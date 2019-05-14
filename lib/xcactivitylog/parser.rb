# frozen_string_literal: true

require 'slf0/parser'
require 'xcactivitylog/objects'

module XCActivityLog
  class Parser < SLF0::Parser
    class S < SLF0::Token::Stream
      def initialize(tokens, class_deserializer:)
        super(tokens, class_deserializer: class_deserializer)
        @version = int('activity log version')
      end

      def deserializer_for(class_ref_num)
        class_name, = @class_deserializer[class_ref_num]
        cls = XCActivityLog.const_get(class_name)
        raise "invalid #{class_name} #{cls}" unless cls < SerializedObject

        lambda do |stream|
          deserialize_instance_of(stream, cls)
        end
      end

      def deserialize_instance_of(stream, cls)
        instance = cls.new
        cls.attributes.each do |attr|
          next if attr.first_version > @version || attr.last_version < @version

          value = stream.send(attr.type, "#{attr.name} for #{cls.name.split('::').last}")
          instance.instance_variable_set(:"@#{attr.name}", value)
        end
        instance.freeze
      end

      def boolean(reason = nil)
        int(reason) != 0
      end

      def nsrange(_reason = nil)
        deserialize_instance_of(self, NSRange)
      end

      def document_location(reason = nil)
        return if shift_nil?

        object(reason).tap do |o|
          raise "expected location, got #{o.class.name} for #{reason}" unless o.is_a?(DVTDocumentLocation)
        end
      end

      EPOCH = Time.new(2001, 1, 1, 0, 0, 0, '+00:00').freeze

      def time(reason = nil)
        EPOCH.+(double(reason)).freeze
      end
    end
    def make_stream(tokens, class_deserializer)
      S.new(tokens, class_deserializer: class_deserializer)
    end
  end
end
