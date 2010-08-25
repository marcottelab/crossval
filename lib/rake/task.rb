def say_with_time message
  say(message)
  result = nil
  time = Benchmark.measure { result = yield }
  say "%.4fs" % time.real, :subitem
  result
end

def say message, subitem=false
  write "#{subitem ? "   ->" : "--"} #{message}"
end

def write(text="")
  puts(text) if verbose
end