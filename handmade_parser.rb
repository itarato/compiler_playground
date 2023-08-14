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
    p("Parse: program")

    ast_node = AstNode.new(:prog)

    while !@tokens.eof?
      block_node = parse_block
      panic!("Cannot read block") if !block_node

      ast_node.add_node_child(block_node)
    end

    ast_node
  end

  def parse_block
    p("Parse: block")

    if @tokens.current.type == Lexeme::KEYWORD_FN
      # Read function defintion
      parse_fn_def
    else
      # Read statement
      parse_stmt
    end
  end

  def parse_fn_def
    p("Parse: fn def")

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
    p("Parse: stmt")

    if @tokens.current.type == Lexeme::NAME && @tokens.next.type == Lexeme::ASSIGN
      parse_assignment
    elsif @tokens.current.type == Lexeme::NAME && @tokens.next.type == Lexeme::PAREN_OPEN
      parse_fn_call
    elsif @tokens.current.type == Lexeme::KEYWORD_IF
      parse_if
    else
      panic!("Unrecognized next token: #{@tokens.inspect}")
    end
  end

  def parse_assignment
    p("Parse: assign")

    node = AstNode.new(:assign)

    assert!(@tokens.current.type == Lexeme::NAME)
    node.add_node_child(AstNode.new(@tokens.current))
    @tokens.forward

    assert!(@tokens.current.type == Lexeme::ASSIGN)
    @tokens.forward

    node_exp = parse_expr
    node.add_node_child(node_exp)

    node
  end

  def parse_fn_call
    p("Parse: fn call")

    node = AstNode.new(:fncall)
    assert!(@tokens.current.type == Lexeme::NAME)
    node.add_node_child(AstNode.new(@tokens.current))
    @tokens.forward

    assert!(@tokens.current.type == Lexeme::PAREN_OPEN, @tokens)
    @tokens.forward

    node_arglist = parse_arglist
    node.add_node_child(node_arglist)

    assert!(@tokens.current.type == Lexeme::PAREN_CLOSE)
    @tokens.forward

    node
  end

  def parse_if
    p("Parse: if")
    node = AstNode.new(:if)

    assert!(@tokens.current.type == Lexeme::KEYWORD_IF)
    @tokens.forward

    assert!(@tokens.current.type == Lexeme::PAREN_OPEN)
    @tokens.forward

    node_expr = parse_expr
    node.add_node_child(node_expr)

    assert!(@tokens.current.type == Lexeme::PAREN_CLOSE)
    @tokens.forward

    assert!(@tokens.current.type == Lexeme::BRACE_OPEN)
    @tokens.forward

    node_stmtlist = parse_stmt_list
    node.add_node_child(node_stmtlist)

    assert!(@tokens.current.type == Lexeme::BRACE_CLOSE)
    @tokens.forward

    node
  end

  def parse_expr
    p("Parse: expr")

    node = AstNode.new(:expr)

    if @tokens.current.type == Lexeme::NUMBER
      node.add_node_child(AstNode.new(@tokens.current))
      @tokens.forward
    elsif @tokens.current.type == Lexeme::NAME && @tokens.next.type == Lexeme::PAREN_OPEN
      node_fn_call = parse_fn_call
      node.add_node_child(node_fn_call)
    elsif @tokens.current.type == Lexeme::NAME
      node.add_node_child(AstNode.new(@tokens.current))
      @tokens.forward
    else
      panic!("Unexpected token: #{@tokens.current}")
    end

    ops = [
      Lexeme::OP_ADD,
      Lexeme::OP_MUL,
      Lexeme::OP_SUB,
      Lexeme::OP_DIV,
    ]
    if ops.include?(@tokens.current.type)
      node.add_node_child(AstNode.new(@tokens.current))
      @tokens.forward

      node_expr = parse_expr
      node.add_node_child(node_expr)
    end

    node
  end

  def parse_arglist
    p("Parse: arg list")

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
    p("Parse: stmt list")

    node = AstNode.new(:stmt_list)

    while @tokens.current.type != until_lexeme_type
      stmt_node = parse_stmt

      node.add_node_child(stmt_node)
    end

    node
  end
end
