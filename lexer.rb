class Lexeme
  NUMBER = 0
  PAREN_OPEN = 1
  PAREN_CLOSE = 2
  OP_ADD = 3
  OP_SUB = 4
  KEYWORD = 5
  NAME = 6
  BRACE_OPEN = 7
  BRACE_CLOSE = 8
  SEMICOLON = 9

  def initialize(lexeme, type)
    @lexeme = lexeme
    @type = type
  end
end

class Lexer
  KEYWORDS = ['while', 'fn', 'if', 'else']

  def initialize(source)
    @source = source
  end

  def read_all
    i = 0
    lexemes = []
    
    while !eof?(i)
      i = pass_while_whitespace(i)
      i, lexeme = read_lexeme(i)
      lexemes.push(lexeme) if lexeme
    end

    lexemes
  end

  def read_lexeme(i)
    return [i, nil] if eof?(i)

    c = @source[i]
    if is_number(c)
      i, lexeme = read_while(i, &method(:is_number))
      return [i, Lexeme.new(lexeme, Lexeme::NUMBER)]
    elsif c == '+'
      return [i + 1, Lexeme.new(c, Lexeme::OP_ADD)]
    elsif c == '-'
      return [i + 1, Lexeme.new(c, Lexeme::OP_SUB)]
    elsif c == '('
      return [i + 1, Lexeme.new(c, Lexeme::PAREN_OPEN)]
    elsif c == ')'
      return [i + 1, Lexeme.new(c, Lexeme::PAREN_CLOSE)]
    elsif c == '{'
      return [i + 1, Lexeme.new(c, Lexeme::BRACE_OPEN)]
    elsif c == '}'
      return [i + 1, Lexeme.new(c, Lexeme::BRACE_CLOSE)]
    elsif c == ';'
      return [i + 1, Lexeme.new(c, Lexeme::SEMICOLON)]
    elsif is_name_start(c)
      i, lexeme = read_while(i, &method(:is_name_tail))
      if KEYWORDS.include?(lexeme)
        return [i, Lexeme.new(lexeme, Lexeme::KEYWORD)]
      else
        return [i, Lexeme.new(lexeme, Lexeme::NAME)]
      end
    end

    $stderr.write("Invalid character: #{c}")
    exit
  end

  def eof?(i)
    i >= @source.size
  end

  def pass_while(i, &block)
    while true
      return i if eof?(i)
      return i unless block.call(@source[i])
      i += 1
    end
  end

  def pass_while_whitespace(i)
    pass_while(i, &method(:is_whitespace))
  end

  def read_while(i, &block)
    start = i
    while true
      if eof?(i) || !block.call(@source[i])
        return [i, @source[start...i]]
      end
      i += 1
    end
  end

  def is_whitespace(c)
    "\n\r\t ".include?(c)
  end

  def is_name_start(c)
    c == "_" || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
  end

  def is_name_tail(c)
    c == "_" || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')
  end

  def is_number(c)
    c >= '0' && c <= '9'
  end    
end
