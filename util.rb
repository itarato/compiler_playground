def panic!(msg)
  $stderr.write("ERROR: #{msg}\n")
  exit
end

def unimplemented!(msg)
  $stderr.write("UNIMPLEMENTED: #{msg}\n")
  exit
end

def epsilon?(o)
  case o
  when Grammar::Elem then o.epsilon?
  when String then o == Grammar::Elem::EPSILON
  else false
  end
end
