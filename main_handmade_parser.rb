require_relative("lexer")
require_relative("handmade_parser")
require("awesome_print")
require("pry")
require("r_o_v")

source = <<~SOURCE
fn speak(word) {
  print(word)
}

a = 1
b = 12 + a
speak(b)
SOURCE

lexer = Lexer.new(source)
tokens = lexer.read_all
ap(tokens)

parser = HandmadeParser.new(tokens)
ast = parser.parse_program

binding.pry