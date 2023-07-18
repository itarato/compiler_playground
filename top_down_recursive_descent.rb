class TopDownRecursiveDescent
  def initialize(grammar, tokens)
    @grammar = grammar
    @tokens = tokens

    @first = @grammar.generate_first_table
  end

  def run

  end

  private
end