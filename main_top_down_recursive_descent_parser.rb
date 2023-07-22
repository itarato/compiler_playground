require("pp")
require_relative("lexer")
require_relative("grammar")
require_relative("top_down_recursive_descent_parser")
require("awesome_print")

if ARGV.size != 2
  $stderr.write("Invalid call. Usage: ruby #{__FILE__} GRAMMAR SOURCE\n")
  exit
end

grammar = Grammar.read(File.read(ARGV[0]))
grammar.dump

lexer = Lexer.new(File.read(ARGV[1]))
tokens = lexer.read_all
ap(tokens)

parser = TopDownRecursiveDescentParser.new(grammar, tokens)
parser.run
