# frozen_string_literal: true

require 'slf0/token'
require 'slf0/tokenizer'

module SLF0
  class Parser
    def initialize(class_deserializer:)
      @class_deserializer = class_deserializer
    end

    def parse!(io)
      tokens = Tokenizer.tokenize(io)

      parse_tokens!(tokens)
    end

    def parse_tokens!(tokens)
      class_names = tokens.grep(SLF0::Token::ClassName).map(&:value)
      tokens.reject! { |t| t.is_a? SLF0::Token::ClassName }
      values = []
      stream = make_stream(tokens, [nil] + class_names.map { |n| [n, @class_deserializer[n]] })
      until tokens.empty?
        values << case tokens.first
                  when SLF0::Token::ClassNameRef
                    stream.object
                  else
                    tokens.shift.value
                  end
      end
      values
    end

    def make_stream(tokens, class_deserializer)
      SLF0::Token::Stream.new(tokens, class_deserializer: class_deserializer)
    end
  end
end
