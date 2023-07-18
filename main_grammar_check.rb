require_relative("util")
require_relative("grammar")

if ARGV.size != 1
  panic!("Usage: #{__FILE__} GRAMMAR")
end

grammar = Grammar.read(File.read(ARGV[0]))
pp(grammar)

grammar.eliminate_left_recursion
pp(grammar.generate_first_table)