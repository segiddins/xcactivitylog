# frozen_string_literal: true

module SLF0
  class Token
    attr_reader :value
    def initialize(value)
      @value = value
    end

    def to_s
      value.to_s
    end

    def inspect
      "#<#{self.class} #{value.inspect}>"
    end

    class ObjectListNil < Token
    end
    class Int < Token
      alias int value
    end
    class ClassName < Token
    end
    class ClassNameRef < Token
    end
    class String < Token
      alias string value
    end
    class Double < Token
      alias double value
    end
    class ObjectList < Token
      alias length value
    end

    class Stream
      def initialize(tokens, class_deserializer:)
        @tokens = tokens
        @class_deserializer = class_deserializer
      end

      def int(reason = nil)
        shift(Int, reason).value
      end

      def string(reason = nil)
        return if shift_nil?(reason)

        shift(String, reason).value
      end

      def double(reason = nil)
        return if shift_nil?

        shift(Double, reason).value
      end

      def object_list(reason = nil)
        return if shift_nil?(reason)

        Array.new(shift(ObjectList, reason).length) do
          object(reason && "object in object list for #{reason}")
        end
      end

      def object(reason = nil)
        deserializer_for(shift(ClassNameRef, reason).value)[self]
      end

      def deserializer_for(class_ref_num)
        @class_deserializer[class_ref_num].last
      end

      def shift_nil?(reason = nil)
        shift(ObjectListNil, reason, raise: false)
      end

      def shift(cls, reason = nil, raise: true)
        unless (token = @tokens.shift)
          raise 'no more tokens'
        end

        unless token.is_a?(cls)
          raise "expected #{cls} got #{token.inspect} for #{reason}" if raise

          @tokens.unshift(token)
          return
        end
        token
      end
    end
  end
end
