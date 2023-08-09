require_relative("util")
require_relative("ast")

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
    grammar.eliminate_left_recursion

    @grammar = grammar
    @tokens = tokens
  end

  def run
    # The current resolution of grammar to tokens.
    mask = [Grammar::Elem.new("Prog")]
    # For backtrack - keep operations for reverts.
    opstack = []
    # Regarding @tokens list.
    token_ptr = 0
    # Regarding the variable: mask.
    mask_ptr = 0

    ast_root = AstNode.new(mask[0])
    ast_current = ast_root

    while true
      puts("\e[93mMask: #{mask} MaskPtr: #{mask_ptr} TokenPtr: #{token_ptr}\e[0m")

      if mask_ptr >= mask.size && token_ptr >= @tokens.size
        # Finish parsing. Success.

        puts("\\o/ PARSE COMPLETED SUCCESSFULLY \\o/")
        return ast_root
      elsif mask_ptr < mask.size && mask[mask_ptr].rule?
        # Replace non-terminal rule to it's next evaluated sequence.

        sequence_candidate = @grammar.sequences_of(mask[mask_ptr])[0]
        op = Op.new(
          elem: mask[mask_ptr],
          mask_ptr: mask_ptr,
          token_ptr: token_ptr,
          range: mask_ptr..(mask_ptr + sequence_candidate.size - 1),
          seq_idx: 0,
        )

        opstack.push(op)

        # Add the non-terminal rule as a child node - so it can be a parent of its own sequence.
        ast_current = ast_current.add_child(mask[mask_ptr]) # ??? Are we sure? How do we now when this seq ends?

        mask = mask[0...mask_ptr] + sequence_candidate + mask[(mask_ptr + 1)..]
      elsif mask_ptr < mask.size && mask[mask_ptr].terminal? && token_ptr < @tokens.size && mask[mask_ptr].accept?(@tokens[token_ptr])
        # Token is matching with terminal rule -> step forward.

        ast_current.add_child(@tokens[token_ptr])

        token_ptr += 1
        mask_ptr += 1

        # We need to somehow detect that the latest sequence has been surpassed and we are on a parent sequence.
        if opstack.last.range.end < mask_ptr
          ast_current = ast_current.parent
        end
      elsif mask_ptr < mask.size && mask[mask_ptr].epsilon?
        # Epsilon rule is found -> step forward (on the mask).

        mask_ptr += 1
      else
        # Backtrack.

        while true
          panic!("No more op for backtrack") if opstack.empty?
          op = opstack.pop

          p("<< BACKTRACK")
          # puts("BT the op: #{op}")
          # puts("BT before: #{mask}")

          # Restore state.
          mask = mask[0...op.range.begin] + [op.elem] + mask[(op.range.end + 1)..]
          token_ptr = op.token_ptr
          mask_ptr = op.mask_ptr

          ast_current = ast_current.reject

          # puts("BT after: #{mask}")

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

            ast_current = ast_current.add_child(op.elem)

            mask = mask[0...mask_ptr] + sequence_candidates[op.seq_idx + 1] + mask[(mask_ptr + 1) ..]

            break
          end

          # Continue backtrack.
        end
      end
    end
  end
end
