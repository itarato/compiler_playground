require_relative("lexer")
require_relative("util")

=begin

Grammar:
{
  Name1 => [
    [t111, t112, ...],
    [t121, t122, ...],
  ],
  Name2 => [
    [t211, t212, ...],
  ]
  ...
}
=end

class Grammar
  class Elem
    attr_reader(:name)

    def initialize(name)
      @name = name
    end

    def to_s = @name
    def inspect = to_s
    def terminal? = !epsilon? && @name[0] >= 'a' && @name[0] <= 'z'
    def rule? = !terminal? && !epsilon?
    def epsilon? = @name == 'ε'

    def accept?(lexeme)
      return false unless terminal?
      case lexeme.type 
      when Lexeme::NUMBER then @name == "num"
      when Lexeme::PAREN_OPEN then @name == "popen"
      when Lexeme::PAREN_CLOSE then @name == "pclose"
      when Lexeme::OP_ADD then @name == "add"
      when Lexeme::OP_SUB then @name == "sub"
      when Lexeme::KEYWORD
        unimplemented!("Keyword accepting is not implemented yet")
      when Lexeme::NAME then @name == "name"
      when Lexeme::BRACE_OPEN then @name == "bopen"
      when Lexeme::BRACE_CLOSE then @name == "bclose"
      when Lexeme::SEMICOLON then @name == "semicolon"
      else panic!("Unknown lexeme: #{lexeme}")
      end
    end
  end

  class << self
    def read(raw)
      Grammar.new(raw.lines.map(&:strip).map do |line|
        name, raw_rule = line.split(" ::= ")

        sequences = raw_rule
          .split(" | ")
          .map { |raw_seq| raw_seq.split(" ").map { |elem| Elem.new(elem) } }

        [name, sequences]
      end.to_h)
    end
  end

  attr_reader(:rules)

  def initialize(rules)
    @rules = rules
  end

  def sequences_of(elem)
    case elem
    when String then @rules[elem]
    when Elem then @rules[elem.name]
    else panic!("Incorrect elem type: #{elem.class.name}")
    end
  end
end
