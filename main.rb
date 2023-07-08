require_relative("lexer")
require_relative("grammar")
require("pp")

if ARGV.size != 2
  $stderr.write("Invalid call. Usage: ruby #{__FILE__} GRAMMAR SOURCE\n")
  exit
end

grammar = Grammar.read(File.read(ARGV[0]))
pp(grammar)

lexer = Lexer.new(File.read(ARGV[1]))
pp(lexer.read_all)