require_relative("util")

class TopDownParser
  class Op
    # Parent of the applied sequence.
    attr_reader(:elem)
    attr_reader(:mask_ptr)
    attr_reader(:token_ptr)
    # Inserted sequence location.
    attr_reader(:range)
    # Inserted sequence index in parent elem's sequence list.
    attr_reader(:seq_idx)

    def initialize(elem:, mask_ptr:, token_ptr:, range:, seq_idx:)
      @elem = elem
      @mask_ptr = mask_ptr
      @token_ptr = token_ptr
      @range = range
      @seq_idx = seq_idx 
    end

    def to_s = "E:#{elem} MP:#{mask_ptr} TP:#{token_ptr} R:#{range} SQI:#{seq_idx}"
  end

  def initialize(grammar, tokens)
    @grammar = grammar
    @tokens = tokens
  end

  def run
    # The currect resolution of grammar to tokens.
    mask = [Grammar::Elem.new("Prog")]
    # For backtrack - keep operations for reverts.
    opstack = []
    # Regarding @tokens list.
    token_ptr = 0
    # Regarding the variable: mask.
    mask_ptr = 0

    while true
      puts("Mask: #{mask} MaskPtr: #{mask_ptr} TokenPtr: #{token_ptr}")

      if mask_ptr >= mask.size && token_ptr >= @tokens.size
        puts("\\o/ PARSE COMPLETED SUCCESSFULLY \\o/")
        return
      elsif mask_ptr < mask.size && mask[mask_ptr].rule?
        sequence_candidate = @grammar.sequences_of(mask[mask_ptr])[0]
        op = Op.new(
          elem: mask[mask_ptr],
          mask_ptr: mask_ptr,
          token_ptr: token_ptr,
          range: mask_ptr..(mask_ptr + sequence_candidate.size - 1),
          seq_idx: 0,
        )

        opstack.push(op)

        mask = mask[0...mask_ptr] + sequence_candidate + mask[(mask_ptr + 1) ..]
      elsif mask_ptr < mask.size && mask[mask_ptr].terminal? && token_ptr < @tokens.size && mask[mask_ptr].accept?(@tokens[token_ptr])
        token_ptr += 1
        mask_ptr += 1
      elsif mask_ptr < mask.size && mask[mask_ptr].epsilon?
        mask_ptr += 1
      else
        # Backtrack

        while true
          panic!("No more op for backtrack") if opstack.empty?
          op = opstack.pop

          puts("BT the op: #{op}")
          puts("BT before: #{mask}")

          # Restore state.
          mask = mask[0...op.range.begin] + [op.elem] + mask[(op.range.end + 1)..]
          token_ptr = op.token_ptr
          mask_ptr = op.mask_ptr

          puts("BT after: #{mask}")

          sequence_candidates = @grammar.sequences_of(op.elem)
          # Go to the next available sequence of a rule.
          if sequence_candidates.size - 1 > op.seq_idx
            new_op = Op.new(
              elem: op.elem,
              mask_ptr: op.mask_ptr,
              token_ptr: op.token_ptr,
              range: mask_ptr..(mask_ptr + sequence_candidates[op.seq_idx + 1].size - 1),
              seq_idx: op.seq_idx + 1,
            )

            opstack.push(new_op)

            mask = mask[0...mask_ptr] + sequence_candidates[op.seq_idx + 1] + mask[(mask_ptr + 1) ..]

            break
          end

          # Continue backtrack.
        end
      end
    end
  end
end
