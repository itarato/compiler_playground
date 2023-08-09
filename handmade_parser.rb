require_relative("ast")
require_relative("util")
require_relative("lexer")

#
# Fixed grammar - handmade top-bottom backtrack style parser.
#
class HandmadeParser
  def initialize(tokens)
    @tokens = tokens
  end

  def parse_program
    token_ptr = 0

    ast_node = AstNode.new(:prog)

    while token_ptr <= @tokens.size
      block_node, token_ptr = parse_block(token_ptr)
      panic!("Cannot read block") if !block_node

      ast_node.add_node_child(block_node)
    end

    ast_node
  end

  def parse_block(token_ptr)
    if @tokens[token_ptr].type == Lexeme::KEYWORD_FN
      # Read function defintion
      parse_fn_def(token_ptr)
    else
      # Read statement
      parse_stmt(token_ptr)
    end
  end

  def parse_fn_def(token_ptr)
    assert!(@tokens[token_ptr].type == Lexeme::KEYWORD_FN)
    token_ptr += 1

    assert!(@tokens[token_ptr].type == Lexeme::NAME)
    node_name = AstNode.new(@tokens[token_ptr])
    token_ptr += 1

    assert!(@tokens[token_ptr].type == Lexeme::PAREN_OPEN)
    token_ptr += 1

    node_arglist, token_ptr = parse_arglist(token_ptr)

    assert!(@tokens[token_ptr].type == Lexeme::PAREN_CLOSE)
    token_ptr += 1

    assert!(@tokens[token_ptr].type == Lexeme::BRACE_OPEN)
    token_ptr += 1

    node_stmtlist, token_ptr = parse_stmt_list(token_ptr, until_lexeme_type: Lexeme::BRACE_CLOSE)

    assert!(@tokens[token_ptr].type == Lexeme::BRACE_CLOSE)
    token_ptr += 1

    ast_node = AstNode.new(:fn_def)
    ast_node.add_node_child(node_name)
    ast_node.add_node_child(node_arglist)

    [ast_node, token_ptr]
  end

  def parse_stmt(token_ptr)
    unimplemented!
  end

  def parse_arglist(token_ptr)
    node = AstNode.new(:arglist)

    while @tokens[token_ptr].type == Lexeme::NAME
      node.add_node_child(AstNode.new(@tokens[token_ptr]))

      token_ptr += 1

      case @tokens[token_ptr].type
      when Lexeme::COMMA then token_ptr += 1
      when Lexeme::PAREN_CLOSE then break
      else panic!("Unexpected token #{@tokens[token_ptr]} in arglist")
      end
    end

    [node, token_ptr]
  end

  def parse_stmt_list(token_ptr, until_lexeme_type:)
    node = AstNode.new(:stmt_list)

    while @tokens[token_ptr].type != until_lexeme_type
      stmt_node, token_ptr = parse_stmt(token_ptr)

      node.add_node_child(stmt_node)
    end

    [node, token_ptr]
  end
end
