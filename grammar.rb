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
  class << self
    def read(raw)
      Grammar.new(raw.lines.map(&:strip).map do |line|
        name, raw_rule = line.split(" ::= ")

        sequences = raw_rule
          .split(" | ")
          .map { _1.split(" ") }

        [name, sequences]
      end.to_h)
    end
  end

  attr_reader(:rules)

  def initialize(rules)
    @rules = rules
  end
end
