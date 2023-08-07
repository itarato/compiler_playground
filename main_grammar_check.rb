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

grammar.eliminate_left_matching_sequences
puts("Eliminate left-matches:\n\n")
grammar.dump ; print("\n")

first_table = grammar.generate_first_table
p("First(?):")
ap(first_table)

follow_table = grammar.generate_follow_table
p("Follow(?):")
ap(follow_table)

start_table = grammar.generate_start_table
p("Start(?):")
ap(start_table)

ll1_parse_table = grammar.generate_ll1_parse_table
p("LL1 parse table:")
ap(ll1_parse_table)
