require_relative("util")
require_relative("grammar")
require("awesome_print")

if ARGV.size != 1
  panic!("Usage: #{__FILE__} GRAMMAR")
end

grammar = Grammar.read(File.read(ARGV[0]))
puts("Grammar:\n\n")
grammar.dump ; print("\n")

grammar.eliminate_left_recursion
puts("Eliminate left-recursion:\n\n")
grammar.dump ; print("\n")

first_table = grammar.generate_first_table
p("First(?):")
ap(first_table)

follow_table = grammar.generate_follow_table
p("Follow(?):")
ap(follow_table)
