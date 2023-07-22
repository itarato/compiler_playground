require_relative("grammar")
require_relative("util")

class TopDownRecursiveDescentParser
  def initialize(grammar, tokens)
    @grammar = grammar
    @tokens = tokens

    @grammar.eliminate_left_recursion

    @lookup_table = @grammar.generate_ll1_parse_table
  end

  def run
    token_ptr = 0
    mask = [START_ELEM]
    mask_ptr = 0

    while true
      puts("Mask: #{mask} MaskPtr: #{mask_ptr} TokenPtr: #{token_ptr}")

      if mask_ptr >= mask.size
        if token_ptr >= @tokens.size
          puts('\o/ PARSING COMPLETED \o/')
          return
        else
          panic!("Got EOF before end of stream")
        end
      elsif mask[mask_ptr].rule?
        elem_key = if @tokens.size <= token_ptr
          EOF_ELEM
        else
          Grammar::Elem.from_lexeme(@tokens[token_ptr])
        end

        next_seq_idx = @lookup_table[[mask[mask_ptr], elem_key]]
        next_seq = @grammar.sequences_of(mask[mask_ptr])[next_seq_idx].select { !_1.epsilon? }

        mask = mask[0...mask_ptr] + next_seq + mask[(mask_ptr + 1)..]
      elsif token_ptr >= @tokens.size
        panic!("No more tokens left")
      elsif mask[mask_ptr].terminal?
        if mask[mask_ptr].accept?(@tokens[token_ptr])
          mask_ptr += 1
          token_ptr += 1
        else
          panic!("Unexpected token")
        end
      else
        panic!("Unexpected call site")
      end
    end
  end
end
