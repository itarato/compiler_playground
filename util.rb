def panic!(msg)
  raise("ERROR: #{msg}")
end

def unimplemented!(msg)
  raise("UNIMPLEMENTED: #{msg}")
end

def epsilon?(o)
  case o
  when Grammar::Elem then o.epsilon?
  when String then o == Grammar::Elem::EPSILON
  else false
  end
end
