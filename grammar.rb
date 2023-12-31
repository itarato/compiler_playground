require_relative("lexer")
require_relative("util")

#
# Wraps a string into a Grammar::Elem.
#
def E(o)
  raise("Unexpected type: #{o.class.name}") unless o.is_a?(String)
  Grammar::Elem.new(o)
end

#
# Grammar format (Backus-Naur form):
#
# {
#   Name1 => [
#     [t111, t112, ...],
#     [t121, t122, ...],
#   ],
#   Name2 => [
#     [t211, t212, ...],
#   ]
#   ...
# }
#
class Grammar
  #
  # Follow represents a temporary follow(A) token during a follow-table generation.
  #
  class Follow
    attr_reader(:elem)

    def initialize(elem)
      @elem = elem
    end

    def ==(other) = other.is_a?(Follow) && @elem == other.elem
    def hash = @elem.hash
    def eql?(other) = self == other
    def to_s = "Follow(#{@elem})"
    def inspect = to_s
  end

  #
  # Elem is a grammar primitive, symbolizing a name (rule or terminal [including eof and epsilon]).
  #
  class Elem
    attr_reader(:name)

    def initialize(name)
      @name = name
    end

    def hash = @name.hash
    def to_s = @name
    def inspect = to_s
    def terminal? = !epsilon? && !eof? && @name[0] >= 'a' && @name[0] <= 'z'
    def rule? = !terminal? && !epsilon? && !eof?
    def epsilon? = @name == EPSILON
    def eof? = @name == EOF
    def ==(other) = other.is_a?(Elem) && @name == other.name
    def eql?(other) = self == other

    #
    # Whether a certain terminal Grammar::Elem is a reference to a Lexeme.
    #
    def accept?(lexeme)
      return false unless terminal?
      self.class.elem_name_for_lexeme(lexeme) == @name
    end

    def self.elem_name_for_lexeme(lexeme)
      case lexeme.type
      when Lexeme::NUMBER then "num"
      when Lexeme::PAREN_OPEN then "popen"
      when Lexeme::PAREN_CLOSE then "pclose"
      when Lexeme::OP_ADD then "add"
      when Lexeme::OP_SUB then "sub"
      when Lexeme::OP_MUL then "mul"
      when Lexeme::OP_DIV then "div"
      when Lexeme::KEYWORD_IF then "if"
      when Lexeme::KEYWORD_WHILE then "while"
      when Lexeme::KEYWORD_FN then "fn"
      when Lexeme::KEYWORD_ELSE then "else"
      when Lexeme::NAME then "name"
      when Lexeme::BRACE_OPEN then "bopen"
      when Lexeme::BRACE_CLOSE then "bclose"
      when Lexeme::SEMICOLON then "semicolon"
      when Lexeme::ASSIGN then "eq"
      when Lexeme::COMMA then "comma"
      else panic!("Unknown lexeme: #{lexeme}")
      end
    end

    def self.from_lexeme(lexeme)
      new(elem_name_for_lexeme(lexeme))
    end
  end

  class << self
    #
    # Parse a raw grammar into the type.
    #
    def read(raw)
      Grammar.new(raw.lines.map(&:strip).map do |line|
        name, raw_rule = line.split(" ::= ")

        sequences = raw_rule
          .split(" | ")
          .map { |raw_seq| raw_seq.split(" ").map { E(_1) } }

        [E(name), sequences]
      end.to_h)
    end
  end

  attr_reader(:rules)

  def initialize(rules)
    @rules = rules

    raise("Missing Prog start rule") unless @rules.key?(E("Prog"))
  end

  def sequences_of(elem)
    @rules[elem]
  end

  def eliminate_left_recursion
    reduce_indirect_left_recursion
  end

  def eliminate_left_matching_sequences
    while (addition = eliminate_left_matching_sequences_step)
      @rules.merge!(addition)
    end
  end

  def eliminate_left_matching_sequences_step
    @rules.each do |name, sequences|
      0.upto(sequences.size - 2) do |i|
        sample_seq = sequences[i]

        (sample_seq.size - 1).downto(0) do |len_idx|
          match_idxs = (i + 1).upto(sequences.size - 1).filter_map do |other_idx|
            other_seq = sequences[other_idx]
            next false if other_seq[0..len_idx] != sample_seq[0..len_idx]
            other_idx
          end

          if !match_idxs.empty?
            match_idxs.push(i)

            new_elem = E(name.name + '"')
            raise if @rules.key?(new_elem)

            match_prefix = sample_seq[0..len_idx]
            suffixes = match_idxs.map do |j|
              suffix = sequences[j][(len_idx + 1)..]
              suffix.empty? ? [EPSILON_ELEM] : suffix
            end

            old_sub = match_prefix + [new_elem]
            sequences.delete_if.with_index { |_, i| match_idxs.include?(i) }
            sequences.concat([old_sub])

            return { new_elem => suffixes }
          end
        end
      end
    end

    false
  end

  #
  # Must be non-left recursive before calling this.
  #
  def generate_first_table
    return @first_table if defined?(@first_table)

    @first_table = {}

    @rules.each do |name, sequences|
      raise if @first_table.key?(name)

      @first_table[name] = find_first_for(name).to_set
    end

    @first_table
  end

  def generate_follow_table
    return @follow_table if defined?(@follow_table)

    @follow_table = {
      START_ELEM => [EOF_ELEM],
    }

    @rules.keys.each do |name|
      next if name == START_ELEM
      raise if @follow_table.key?(name)

      @follow_table[name] = find_right_of(name).uniq
    end

    # Refine:
    while true
      has_change = false

      @follow_table.each do |name, follows|
        new_subs = []
        follows_old = follows.clone

        follows.delete_if do |follow|
          next false if !follow.is_a?(Follow)

          new_subs += @follow_table[follow.elem]
        end

        follows.concat(new_subs).uniq!

        has_change |= follows_old != follows
      end

      break if !has_change
    end

    # Filter out non-resolvable placeholders:
    @follow_table.each_value do |follows|
      follows.delete_if { _1.is_a?(Follow) }
    end

    @follow_table
  end

  #
  # Format:
  #
  # {
  #   [Elem, Idx(seq)] -> [terminal, ...]
  # }
  #
  def generate_start_table
    return @start_table if defined?(@start_table)

    @start_table = {}

    first_table = generate_first_table
    follow_table = generate_follow_table

    @rules.each do |name, sequences|
      sequences.each_with_index do |sequence, index|
        head = sequence.first
        start_set = if head.terminal?
          [head]
        elsif head.rule?
          _set = first_table[head]
          has_epsilon = false
          _set.delete_if do |elem|
            next false if !elem.epsilon?

            has_epsilon = true
            true
          end

          if has_epsilon
            _set.merge(follow_table[name])
          end

          _set
        elsif head.epsilon?
          follow_table[name]
        end

        raise if @start_table.key?([name, index])

        @start_table[[name, index]] = start_set
      end
    end

    @start_table
  end

  #
  # Format:
  #
  # {
  #   [Elem, terminal] -> Idx(seq)
  # }
  #
  def generate_ll1_parse_table
    return @ll1_parse_table if defined?(@ll1_parse_table)

    @ll1_parse_table = {}

    generate_start_table.each do |(elem, index), terminals|
      terminals.each do |terminal|
        if @ll1_parse_table.key?([elem, terminal]) && !terminal.eof?
          panic!("Duplicate key for LL1 parse table. Key: #{elem}-#{terminal}")
        end

        @ll1_parse_table[[elem, terminal]] = index
      end
    end

    @ll1_parse_table
  end

  def dump
    @rules.each do |name, seqs|
      puts("#{name} ::= #{seqs.map { _1.join(" ") }.join(' | ') }")
    end
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

  def find_right_of(elem)
    @rules.flat_map do |name, sequences|
      sequences.flat_map do |seq|
        # looking for B -> xAy
        if (i = seq.index(elem))
          if i + 1 < seq.size # Has y
            follow = seq[i + 1]
            if follow.terminal? # y is terminal
              [follow]
            else # y is a rule -> First(y)
              generate_first_table[follow].map do |first_elem|
                if first_elem.epsilon? # First(y) has epsilon -> Follow(y)
                  Follow.new(follow)
                else # First(y) is ok
                  first_elem
                end
              end
            end
          else # Has no y -> Follow(B)
            [Follow.new(name)]
          end
        else # No B -> _A_ occurrence.
          []
        end
      end
    end
  end

  def reduce_indirect_left_recursion
    inloop = []
    new_rules = {}

    @rules.each do |base, sequences|
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

    new_elem = E(elem.name + "'")
    raise if @rules.key?(new_elem)

    sequences.map! { _1.push(new_elem) }
    left_ref_seqs.map! { _1[1..] + [new_elem] }
    left_ref_seqs.push([EPSILON_ELEM])

    { new_elem => left_ref_seqs }
  end
end

EPSILON = 'ε'
EOF = 'eof'
EOF_ELEM = E(EOF)
START_ELEM = E("Prog")
EPSILON_ELEM = E(EPSILON)
