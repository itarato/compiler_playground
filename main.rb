require("pp")
require_relative("lexer")
require_relative("grammar")
require_relative("top_down_parser")

if ARGV.size != 2
  $stderr.write("Invalid call. Usage: ruby #{__FILE__} GRAMMAR SOURCE\n")
  exit
end

grammar = Grammar.read(File.read(ARGV[0]))
pp(grammar)

lexer = Lexer.new(File.read(ARGV[1]))
tokens = lexer.read_all
pp(tokens)

top_down_parser = TopDownParser.new(grammar, tokens)
top_down_parser.run