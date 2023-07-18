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
      when Lexeme::OP_MUL then @name == "mul"
      when Lexeme::OP_DIV then @name == "div"
      when Lexeme::KEYWORD
        unimplemented!("Keyword accepting is not implemented yet")
      when Lexeme::NAME then @name == "name"
      when Lexeme::BRACE_OPEN then @name == "bopen"
      when Lexeme::BRACE_CLOSE then @name == "bclose"
      when Lexeme::SEMICOLON then @name == "semicolon"
      else panic!("Unknown lexeme: #{lexeme}")
      end
    end

    def ==(other)
      # pp("EQ: #{self} <-> #{other}")
      case other
      when String then @name == other
      when Elem then @name == other.name
      else panic!("Unexpected eq comp: self:#{self} other:#{other}")
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

    raise("Missing Prog start rule") unless @rules.key?("Prog")
  end

  def sequences_of(elem)
    case elem
    when String then @rules[elem]
    when Elem then @rules[elem.name]
    else panic!("Incorrect elem type: #{elem.class.name}")
    end
  end

  def eliminate_left_recursion
    reduce_indirect_left_recursion
  end

  # Must be non-left recursive before calling this.
  def generate_first_table
    @first_table ||= @rules.map do |name, sequences|
      [name, find_first_for(Elem.new(name)).map(&:name).to_set]
    end.to_h
  end

  def generate_follow_table
    first_table = generate_first_table
  end

  private

  def find_first_for(elem)
    sequences_of(elem).flat_map do |seq|
      if seq.first.rule?
        find_first_for(seq.first)
      else
        [seq.first]  
      end
    end
  end

  def reduce_indirect_left_recursion
    inloop = []
    new_rules = {}

    @rules.each do |name, sequences|
      base = Elem.new(name)
      
      inloop.each do |sub_elem|
        new_sequences = []
        sequences.delete_if do |sequence|
          if sequence.first == sub_elem
            new_sequences += sequences_of(sub_elem).map { _1 + sequence[1..] }

            true
          else
            false
          end
        end

        sequences.concat(new_sequences)
      end

      new_rules.merge!(eliminate_direct_left_recursion(base, sequences))

      inloop.push(base)
    end

    @rules.merge!(new_rules)

    pp(@rules)
  end

  def eliminate_direct_left_recursion(elem, sequences)
    left_ref_seqs = []
    sequences.delete_if do |seq|
      next false if seq.first != elem
      left_ref_seqs.push(seq)
      true
    end
    
    return {} if left_ref_seqs.empty?

    panic!("No non-recursive sequences left for rule #{elem}") if sequences.empty?

    new_elem = Elem.new(elem.name + "'")
    sequences.map! { _1.push(new_elem) }
    left_ref_seqs.map! { _1[1..] + [new_elem] }
    left_ref_seqs.push([Elem.new("ε")])

    { new_elem.name => left_ref_seqs }
  end
end
