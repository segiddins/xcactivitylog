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

      def int(&reason_blk)
        shift(Int, &reason_blk).value
      end

      def string(&reason_blk)
        return if shift_nil?(&reason_blk)

        shift(String, &reason_blk).value
      end

      def double(&reason_blk)
        return if shift_nil?

        shift(Double, &reason_blk).value
      end

      def object_list(&reason_blk)
        return if shift_nil?(&reason_blk)

        length = shift(ObjectList, &reason_blk).length
        Array.new(length) do
          object { reason_blk && "object #{length} in object list for #{reason_blk&.call}" }
        end
      end

      def object(&reason_blk)
        return if shift_nil?(&reason_blk)

        deserializer_for(shift(ClassNameRef, &reason_blk).value)[self]
      end

      def deserializer_for(class_ref_num)
        @class_deserializer[class_ref_num].last
      end

      def shift_nil?(&reason_blk)
        shift(ObjectListNil, raise: false, &reason_blk)
      end

      def shift(cls, raise: true, &reason_blk)
        unless (token = @tokens.shift)
          raise 'no more tokens'
        end

        unless token.is_a?(cls)
          unexpected_token!(cls, token, &reason_blk) if raise

          @tokens.unshift(token)
          return
        end
        token
      end

      def unexpected_token!(expected_class, token, &reason_blk)
        raise "expected #{expected_class} got #{token.inspect} for #{reason_blk&.call}"
      end
    end
  end
end
