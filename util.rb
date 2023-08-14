require("ap")
# require("pry-byebug")

def panic!(msg = "")
  # binding.pry
  raise("ERROR: #{msg}")
end

def unimplemented!(msg = "")
  raise("UNIMPLEMENTED: #{msg}")
end

def epsilon?(o)
  case o
  when Grammar::Elem then o.epsilon?
  when String then o == Grammar::Elem::EPSILON
  else false
  end
end

def assert!(v, *dumps)
  return if v
  ap(dumps)
  raise("Assertion failed: #{v}")
end
