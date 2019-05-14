# frozen_string_literal: true

module SLF0
  class Tokenizer
    attr_reader :scanner
    def initialize(slf0)
      @scanner = StringScanner.new(slf0)
    end
    private_class_method :new

    def self.tokenize(slf0)
      new(slf0).tokenize
    end

    def tokenize
      skip_header!
      tokenize_body!
    end

    def skip_header!
      raise 'missing header' unless scanner.skip(/SLF0/)
    end

    def tokenize_body!
      body = []
      until scanner.eos?
        object = tokenize_field || tokenize_double_field || tokenize_object_list_nil
        raise "malformed no object: #{scanner.rest.inspect}\n\nafter: #{body.inspect}" unless object

        body << object
      end
      body
    end

    def tokenize_field
      raise 'no int found' unless (int = scanner.scan(/\d+/).to_i)

      case scanner.get_byte
      when '#'
        SLF0::Token::Int.new int
      when '%'
        SLF0::Token::ClassName.new scanner.scan(/.{#{int}}/).freeze
      when '@'
        SLF0::Token::ClassNameRef.new int
      when '"'
        SLF0::Token::String.new scanner.scan(/.{#{int}}/).tr("\r", "\n").freeze
      when '('
        SLF0::Token::ObjectList.new int
      else
        scanner.unscan
        nil
      end
    end

    def tokenize_double_field
      return unless (hex = scanner.scan(/[0-9a-fA-F]*\^/)&.chomp('^'))

      double = [hex.to_i(16)].pack('Q<').unpack1('G')
      SLF0::Token::Double.new double
    end

    def tokenize_object_list_nil
      return unless scanner.skip(/-/)

      SLF0::Token::ObjectListNil.new nil
    end
  end
end
