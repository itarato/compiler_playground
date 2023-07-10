def panic!(msg)
  $stderr.write("ERROR: #{msg}\n")
  exit
end

def unimplemented!(msg)
  $stderr.write("UNIMPLEMENTED: #{msg}\n")
  exit
end
