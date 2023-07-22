require_relative("grammar")
require_relative("util")

class TopDownRecursiveDescentParser
  def initialize(grammar, tokens)
    @grammar = grammar
    @tokens = tokens
    @lookup_table = @grammar.generate_ll1_parse_table
  end

  def run
    token_ptr = 0
    mask = [START_ELEM]
    mask_ptr = 0

    while true
      if mask_ptr >= mask.size
        panic!("Mask overflow")
      elsif mask[mask_ptr].eof?
      end
    end
  end

  private
end