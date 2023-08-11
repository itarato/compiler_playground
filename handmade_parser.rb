require_relative("ast")
require_relative("util")
require_relative("lexer")

#
# Fixed grammar - handmade top-bottom backtrack style parser.
#
class HandmadeParser
  def initialize(tokens)
    @tokens = TokenStream.new(tokens)
  end

  def parse_program
    ast_node = AstNode.new(:prog)

    while !@tokens.eof?
      block_node = parse_block
      panic!("Cannot read block") if !block_node

      ast_node.add_node_child(block_node)
    end

    ast_node
  end

  def parse_block
    if @tokens.current.type == Lexeme::KEYWORD_FN
      # Read function defintion
      parse_fn_def
    else
      # Read statement
      parse_stmt
    end
  end

  def parse_fn_def
    assert!(@tokens.current.type == Lexeme::KEYWORD_FN)
    @tokens.forward

    assert!(@tokens.current.type == Lexeme::NAME)
    node_name = AstNode.new(@tokens.current)
    @tokens.forward

    assert!(@tokens.current.type == Lexeme::PAREN_OPEN)
    @tokens.forward

    node_arglist = parse_arglist

    assert!(@tokens.current.type == Lexeme::PAREN_CLOSE)
    @tokens.forward

    assert!(@tokens.current.type == Lexeme::BRACE_OPEN)
    @tokens.forward

    node_stmtlist = parse_stmt_list(until_lexeme_type: Lexeme::BRACE_CLOSE)

    assert!(@tokens.current.type == Lexeme::BRACE_CLOSE)
    @tokens.forward

    ast_node = AstNode.new(:fn_def)
    ast_node.add_node_child(node_name)
    ast_node.add_node_child(node_arglist)
    ast_node.add_node_child(node_stmtlist)

    ast_node
  end

  def parse_stmt
    unimplemented!
  end

  def parse_arglist
    node = AstNode.new(:arglist)

    while @tokens.current.type == Lexeme::NAME
      node.add_node_child(AstNode.new(@tokens.current))

      @tokens.forward

      case @tokens.current.type
      when Lexeme::COMMA then @tokens.forward
      when Lexeme::PAREN_CLOSE then break
      else panic!("Unexpected token #{@tokens.current} in arglist")
      end
    end

    node
  end

  def parse_stmt_list(until_lexeme_type:)
    node = AstNode.new(:stmt_list)

    while @tokens.current.type != until_lexeme_type
      stmt_node = parse_stmt

      node.add_node_child(stmt_node)
    end

    node
  end
end
