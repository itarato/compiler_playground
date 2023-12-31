require("pp")
require_relative("lexer")
require_relative("grammar")
require_relative("top_down_parser")
require("awesome_print")
require("pry")
require("r_o_v")

if ARGV.size != 2
  $stderr.write("Invalid call. Usage: ruby #{__FILE__} GRAMMAR SOURCE\n")
  exit
end

grammar = Grammar.read(File.read(ARGV[0]))
grammar.dump

lexer = Lexer.new(File.read(ARGV[1]))
tokens = lexer.read_all
ap(tokens)

parser = TopDownParser.new(grammar, tokens)
ast = parser.run

binding.pry